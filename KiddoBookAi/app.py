import os
import re
import streamlit as st
import google.generativeai as genai
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
import base64
import requests
from io import BytesIO
from PIL import Image
import json
import time

# CONFIGURATION
# ==================================================

# Try to get API keys from environment variables
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
HF_TOKEN = os.getenv("HF_TOKEN")

# Configure Google Gemini
if GOOGLE_API_KEY:
    genai.configure(api_key=GOOGLE_API_KEY)
    model = genai.GenerativeModel("gemini-2.5-flash")
else:
    st.warning("Google API key not found. Please set GOOGLE_API_KEY environment variable.")

# Hugging Face Configuration
HF_FLUX_API_URL = "https://router.huggingface.co/replicate/v1/models/black-forest-labs/flux-2-dev/predictions"

# Field-specific prompt configurations
FIELD_CONFIGS = {
    "Computer Science": {
        "image_prompt": "digital art, futuristic, code patterns, circuit boards, technology theme",
        "text_prompt_prefix": "Focus on algorithms, programming, and computational thinking. ",
        "color_scheme": "#2563EB",  # Blue
        "icon": "💻"
    },
    "Mathematics": {
        "image_prompt": "geometric patterns, mathematical formulas, symmetry, abstract shapes",
        "text_prompt_prefix": "Focus on logical reasoning, problem-solving, and mathematical concepts. ",
        "color_scheme": "#DC2626",  # Red
        "icon": "🧮"
    },
    "Science": {
        "image_prompt": "laboratory equipment, molecular structures, natural phenomena, scientific diagrams",
        "text_prompt_prefix": "Focus on scientific method, experiments, and evidence-based learning. ",
        "color_scheme": "#059669",  # Green
        "icon": "🔬"
    },
    "History": {
        "image_prompt": "ancient artifacts, historical maps, vintage documents, classical architecture",
        "text_prompt_prefix": "Focus on historical context, timelines, and cause-effect relationships. ",
        "color_scheme": "#D97706",  # Amber
        "icon": "📜"
    },
    "Literature": {
        "image_prompt": "bookshelves, quill pens, parchment, literary symbols, classic literature aesthetic",
        "text_prompt_prefix": "Focus on narrative analysis, literary devices, and character development. ",
        "color_scheme": "#7C3AED",  # Purple
        "icon": "📖"
    },
    "Art & Design": {
        "image_prompt": "color palette, brush strokes, design elements, creative composition",
        "text_prompt_prefix": "Focus on creative expression, design principles, and artistic techniques. ",
        "color_scheme": "#DB2777",  # Pink
        "icon": "🎨"
    },
    "Business & Economics": {
        "image_prompt": "charts, graphs, business icons, financial symbols, professional workspace",
        "text_prompt_prefix": "Focus on practical applications, case studies, and real-world scenarios. ",
        "color_scheme": "#0891B2",  # Cyan
        "icon": "💼"
    },
    "Health & Medicine": {
        "image_prompt": "medical symbols, anatomy diagrams, health icons, wellness themes",
        "text_prompt_prefix": "Focus on health education, preventive care, and medical knowledge. ",
        "color_scheme": "#65A30D",  # Lime
        "icon": "⚕️"
    },
    "Engineering": {
        "image_prompt": "mechanical parts, engineering blueprints, structural designs, innovation themes",
        "text_prompt_prefix": "Focus on practical engineering principles, design thinking, and problem-solving. ",
        "color_scheme": "#475569",  # Gray
        "icon": "⚙️"
    },
    "Psychology": {
        "image_prompt": "brain diagrams, psychological symbols, human behavior patterns, mind maps",
        "text_prompt_prefix": "Focus on human behavior, cognitive processes, and psychological theories. ",
        "color_scheme": "#C026D3",  # Fuchsia
        "icon": "🧠"
    },
    "Languages": {
        "image_prompt": "language symbols, global communication, speech bubbles, multicultural themes",
        "text_prompt_prefix": "Focus on language acquisition, communication skills, and cultural context. ",
        "color_scheme": "#EA580C",  # Orange
        "icon": "🗣️"
    },
    "General Education": {
        "image_prompt": "graduation cap, open book, learning icons, academic achievement",
        "text_prompt_prefix": "Focus on comprehensive learning, critical thinking, and interdisciplinary connections. ",
        "color_scheme": "#4F46E5",  # Indigo
        "icon": "🎓"
    }
}

# Book type configurations with field-specific adjustments
BOOK_TYPE_CONFIGS = {
    "Textbook": {
        "structure": "1. Learning Objectives\n2. Key Terms\n3. Detailed Explanation\n4. Examples\n5. Practice Problems\n6. Summary",
        "tone": "Academic, formal"
    },
    "Exam-prep Notes": {
        "structure": "1. Quick Definition\n2. Key Formulas\n3. Common Questions\n4. Memory Tricks\n5. Mistakes to Avoid",
        "tone": "Concise, practical"
    },
    "Story-style Guide": {
        "structure": "1. Story Introduction\n2. Character Dialogues\n3. Real-world Analogy\n4. Practical Application\n5. Moral Lesson",
        "tone": "Narrative, engaging"
    },
    "Research Manual": {
        "structure": "1. Research Context\n2. Methodologies\n3. Case Studies\n4. Data Analysis\n5. References",
        "tone": "Technical, precise"
    },
    "Beginner's Handbook": {
        "structure": "1. Simple Definition\n2. Step-by-Step Guide\n3. Hands-on Exercise\n4. Common Questions\n5. Progress Checklist",
        "tone": "Friendly, simple"
    }
}

# Topic Processing Engine 
# ==================================================
def clean_topics(raw_text: str) -> list[str]:
    topics = []
    lines = raw_text.split("\n")
    for line in lines:
        line = re.sub(r"^[\d\.\)\-\•\s]+", "", line.strip())
        parts = re.split(r",| and ", line)
        for part in parts:
            topic = part.strip()
            if topic:
                topics.append(topic)
    return topics

# Field-aware image prompt generation
def generate_field_specific_image_prompt(field: str, book_name: str, book_type: str, book_description: str = "") -> str:
    """Generate a field-specific image prompt for cover generation"""
    field_config = FIELD_CONFIGS.get(field, FIELD_CONFIGS["General Education"])
    
    base_prompt = f"Professional book cover design for '{book_name}', "
    
    # Add field-specific elements
    base_prompt += f"{field.lower()} themed, {field_config['image_prompt']}, "
    
    # Add book type specific elements
    if book_type == "Story-style Guide":
        base_prompt += "narrative style, "
    elif book_type == "Research Manual":
        base_prompt += "technical and precise, "
    elif book_type == "Beginner's Handbook":
        base_prompt += "friendly and accessible, "
    
    # Add book description if available
    if book_description:
        base_prompt += f"theme: {book_description[:50]}, "
    
    # Add final styling
    base_prompt += "clean design, minimalist, high quality, 4k, trending on artstation, professional book cover"
    
    return base_prompt

# Hugging Face Image Generation Function
# ==================================================
def generate_book_cover_hf(book_name: str, book_type: str, field: str, book_description: str = ""):
    """Generate book cover using Hugging Face FLUX model with field-specific prompts"""
    
    if not HF_TOKEN:
        st.error("Hugging Face token not configured. Please set HF_TOKEN environment variable.")
        return None
    
    try:
        # Generate field-specific prompt
        prompt = generate_field_specific_image_prompt(field, book_name, book_type, book_description)
        
        headers = {
            "Authorization": f"Bearer {HF_TOKEN}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "input": {
                "prompt": prompt,
                "num_outputs": 1,
                "aspect_ratio": "1:1",  # Square format for book cover
                "guidance_scale": 7.5,
                "num_inference_steps": 28
            }
        }
        
        # Make the API request
        response = requests.post(HF_FLUX_API_URL, headers=headers, json=payload)
        
        if response.status_code == 200:
            response_data = response.json()
            
            # Check if prediction URL is available
            if 'urls' in response_data and 'get' in response_data['urls']:
                # Poll for result (Hugging Face async API)
                prediction_url = response_data['urls']['get']
                
                # Wait for prediction to complete
                for _ in range(30):  # Try for 30 seconds
                    prediction_response = requests.get(prediction_url, headers=headers)
                    prediction_data = prediction_response.json()
                    
                    if prediction_data['status'] == 'succeeded':
                        # Get the image URL from the output
                        if 'output' in prediction_data:
                            image_url = prediction_data['output'][0] if isinstance(prediction_data['output'], list) else prediction_data['output']
                            
                            # Download the image
                            image_response = requests.get(image_url)
                            if image_response.status_code == 200:
                                # Save the image with field in filename
                                image_path = f"cover_{field.replace(' ', '_')}_{book_name.replace(' ', '_')[:20]}.png"
                                with open(image_path, "wb") as f:
                                    f.write(image_response.content)
                                return image_path
                    
                    elif prediction_data['status'] == 'failed':
                        st.error(f"Image generation failed: {prediction_data.get('error', 'Unknown error')}")
                        return None
                    
                    time.sleep(2)  # Wait 2 seconds before polling again
                
                st.warning("Image generation timed out. Please try again.")
                return None
            else:
                st.error("Invalid response from Hugging Face API")
                return None
                
        else:
            st.error(f"Hugging Face API Error: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        st.error(f"Error generating cover: {str(e)}")
        return None

# Alternative simpler Hugging Face API (using Inference API)
def generate_book_cover_simple(book_name: str, book_type: str, field: str, book_description: str = ""):
    """Simpler alternative using Hugging Face Inference API with field-specific prompts"""
    
    if not HF_TOKEN:
        return None
    
    try:
        # Generate field-specific prompt
        prompt = generate_field_specific_image_prompt(field, book_name, book_type, book_description)
        
        # Use a different Hugging Face endpoint that's more straightforward
        API_URL = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        
        payload = {
            "inputs": prompt,
            "parameters": {
                "negative_prompt": "ugly, blurry, text, watermark, signature, distorted, bad quality",
                "num_inference_steps": 30,
                "guidance_scale": 7.5,
                "height": 512,
                "width": 512
            }
        }
        
        response = requests.post(API_URL, headers=headers, json=payload)
        
        if response.status_code == 200:
            # Save the image with field in filename
            image_path = f"cover_{field.replace(' ', '_')}_{book_name.replace(' ', '_')[:20]}.png"
            with open(image_path, "wb") as f:
                f.write(response.content)
            return image_path
        else:
            st.error(f"Hugging Face Error: {response.status_code}")
            return None
            
    except Exception as e:
        st.error(f"Error: {str(e)}")
        return None

# LLM Interaction Layer (Google Gemini) with field-specific prompts
# ==================================================
def generate_field_specific_text_prompt(topic: str, book_type: str, field: str, book_name: str = "", book_description: str = "") -> str:
    """Generate a field-specific text prompt for content generation"""
    field_config = FIELD_CONFIGS.get(field, FIELD_CONFIGS["General Education"])
    book_type_config = BOOK_TYPE_CONFIGS.get(book_type, BOOK_TYPE_CONFIGS["Textbook"])
    
    prompt = f"""Write a chapter on "{topic}" for a {book_type.lower()} in the field of {field.lower()}.

Book: {book_name if book_name else 'Unnamed Book'}
Field: {field}
Description: {book_description if book_description else 'Not provided'}

{field_config['text_prompt_prefix']}

Structure this chapter with:
{book_type_config['structure']}

Tone: {book_type_config['tone']}
Style: Educational, engaging, and practical for {field.lower()} students.

Focus on:
1. Core concepts relevant to {field}
2. Practical applications in {field}
3. Common challenges and solutions
4. Real-world examples from {field}
5. Connections to broader {field} knowledge

Make it comprehensive yet accessible, with clear explanations suitable for learners."""
    
    return prompt

def explain_topic(topic: str, book_type: str, field: str, book_name: str = "", book_description: str = "") -> str:
    """Generate field-specific content based on book type"""
    
    try:
        prompt = generate_field_specific_text_prompt(topic, book_type, field, book_name, book_description)
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        return f"[Error generating content: {str(e)}]\n\nDebug info: Field={field}, Book Type={book_type}"

# Content Generator with Cover Image Support
# ==================================================
def generate_pdf(book_text: str, book_name: str = "Book", book_type: str = "Textbook", 
                 field: str = "General Education", cover_image_path: str = None, 
                 filename: str = "kiddoBookAi.pdf") -> None:
    
    c = canvas.Canvas(filename, pagesize=A4)
    width, height = A4

    margin_x, margin_y = 50, 50
    line_height = 14
    
    # Get field configuration for styling
    field_config = FIELD_CONFIGS.get(field, FIELD_CONFIGS["General Education"])
    field_color = field_config.get("color_scheme", "#4F46E5")
    
    # Convert hex color to RGB for reportlab
    def hex_to_rgb(hex_color):
        hex_color = hex_color.lstrip('#')
        return tuple(int(hex_color[i:i+2], 16)/255 for i in (0, 2, 4))
    
    field_rgb = hex_to_rgb(field_color)
    
    # COVER PAGE (if image exists)
    if cover_image_path and os.path.exists(cover_image_path):
        try:
            # Create a cover page with field styling
            c.setFont("Helvetica-Bold", 24)
            c.setFillColorRGB(*field_rgb)
            c.drawString(margin_x, height - 150, book_name)
            
            c.setFont("Helvetica", 14)
            c.setFillColorRGB(0.3, 0.3, 0.3)
            c.drawString(margin_x, height - 200, f"A {book_type}")
            
            # Add field icon and name
            c.setFont("Helvetica-Bold", 12)
            c.setFillColorRGB(*field_rgb)
            c.drawString(margin_x, height - 230, f"Field: {field}")
            
            # Add the generated cover image
            img = ImageReader(cover_image_path)
            img_width, img_height = img.getSize()
            
            # Scale image to fit
            scale = min((width-100)/img_width, (height-300)/img_height)
            scaled_width = img_width * scale
            scaled_height = img_height * scale
            
            # Position image
            img_x = (width - scaled_width) / 2
            img_y = (height - scaled_height) / 2 - 50
            
            c.drawImage(cover_image_path, img_x, img_y, 
                       width=scaled_width, height=scaled_height)
            
            # Footer on cover
            c.setFont("Helvetica-Oblique", 10)
            c.setFillColorRGB(0.5, 0.5, 0.5)
            c.drawString(margin_x, 50, "Generated with kiddoBookAi")
            
            c.showPage()  # Move to next page for content
            
        except Exception as e:
            st.warning(f"Could not add cover image: {str(e)}")
    
    # BOOK CONTENT PAGE
    # Header with field styling
    c.setFont("Helvetica-Bold", 18)
    c.setFillColorRGB(*field_rgb)
    c.drawString(margin_x, height - margin_y, f"kiddoBookAi Presents:")
    
    c.setFont("Helvetica-Bold", 16)
    c.setFillColorRGB(*field_rgb)
    c.drawString(margin_x, height - margin_y - 25, f"{book_name}")
    
    # Field and book type info
    c.setFont("Helvetica", 10)
    c.setFillColorRGB(0.3, 0.3, 0.3)
    c.drawString(margin_x, height - margin_y - 45, f"Field: {field}")
    c.drawString(margin_x, height - margin_y - 60, f"Book Type: {book_type}")
    c.drawString(margin_x, height - margin_y - 75, "Generated with kiddoBookAi")
    
    # Content
    y = height - margin_y - 95
    c.setFont("Helvetica", 11)
    c.setFillColorRGB(0.1, 0.1, 0.1)
    
    lines = book_text.split("\n")
    for line in lines:
        if y <= margin_y:
            c.showPage()
            y = height - margin_y
            c.setFont("Helvetica", 11)
            c.setFillColorRGB(0.1, 0.1, 0.1)
        c.drawString(margin_x, y, line)
        y -= line_height

    c.save()

# Streamlit UI
# ==================================================
st.set_page_config(
    page_title="kiddoBookAi",
    page_icon="📚",
    layout="wide"
)

# Initialize session state
if 'theme' not in st.session_state:
    st.session_state.theme = "System Default"
if 'generated' not in st.session_state:
    st.session_state.generated = False
if 'book_content' not in st.session_state:
    st.session_state.book_content = ""
if 'pdf_filename' not in st.session_state:
    st.session_state.pdf_filename = ""
if 'cover_image_path' not in st.session_state:
    st.session_state.cover_image_path = None
if 'selected_field' not in st.session_state:
    st.session_state.selected_field = "General Education"
for key in ['book_name', 'book_type', 'book_description', 'raw_input']:
    if key not in st.session_state:
        st.session_state[key] = ""

# Check API availability
api_status = {
    "Google Gemini": GOOGLE_API_KEY is not None,
    "Hugging Face": HF_TOKEN is not None
}

# App Header with field selector
st.title("📚 kiddoBookAi")
st.markdown("Create educational books with AI-generated covers")

# Field Selection Section
st.markdown("### 🎯 Select Field of Study")
st.markdown("Choose a field to get customized content and cover generation")

# Create columns for field selection
col1, col2, col3, col4 = st.columns(4)

# Display fields in a grid layout
fields = list(FIELD_CONFIGS.keys())
fields_per_column = len(fields) // 4 + (1 if len(fields) % 4 > 0 else 0)

for i in range(4):
    with [col1, col2, col3, col4][i]:
        start_idx = i * fields_per_column
        end_idx = min((i + 1) * fields_per_column, len(fields))
        
        for field in fields[start_idx:end_idx]:
            field_config = FIELD_CONFIGS[field]
            is_selected = st.session_state.selected_field == field
            
            # Create a styled button for each field
            if st.button(
                f"{field_config['icon']} {field}",
                key=f"field_{field}",
                use_container_width=True,
                type="primary" if is_selected else "secondary"
            ):
                st.session_state.selected_field = field
                st.rerun()

# Show selected field with styling
selected_field_config = FIELD_CONFIGS[st.session_state.selected_field]
st.markdown(f"""
<div style="background-color: {selected_field_config['color_scheme']}10; padding: 15px; border-radius: 10px; border-left: 5px solid {selected_field_config['color_scheme']}; margin: 10px 0;">
    <h4 style="color: {selected_field_config['color_scheme']}; margin: 0;">
        {selected_field_config['icon']} Selected Field: {st.session_state.selected_field}
    </h4>
    <p style="margin: 5px 0 0 0; color: #666;">
        Custom prompts will be generated for {selected_field_config['text_prompt_prefix'].lower()}
    </p>
</div>
""", unsafe_allow_html=True)

# API Status Indicator
status_cols = st.columns(len(api_status))
for idx, (service, status) in enumerate(api_status.items()):
    with status_cols[idx]:
        if status:
            st.success(f"✅ {service}")
        else:
            st.warning(f"⚠️ {service}")

# Main Input Section
col_input1, col_input2 = st.columns(2)

with col_input1:
    st.subheader("Book Details")
    book_name = st.text_input(
        "Book Title *",
        value=st.session_state.book_name,
        placeholder=f"e.g., The Complete Guide to {st.session_state.selected_field}",
        help="Enter a title for your book"
    )
    
    book_description = st.text_area(
        "Description (Optional)",
        value=st.session_state.book_description,
        height=100,
        placeholder=f"Describe what this {st.session_state.selected_field.lower()} book is about... This helps generate better content and cover."
    )
    
    book_type = st.selectbox(
        "Book Style *",
        ["Textbook", "Exam-prep Notes", "Story-style Guide", "Research Manual", "Beginner's Handbook"],
        index=0
    )
    
    # Show field-specific preview
    with st.expander("📋 Field-specific customization preview"):
        field_config = FIELD_CONFIGS[st.session_state.selected_field]
        st.markdown(f"**Image Style:** {field_config['image_prompt']}")
        st.markdown(f"**Content Focus:** {field_config['text_prompt_prefix']}")
        st.markdown(f"**Color Theme:** {field_config['color_scheme']}")
    
    # Cover generation option
    generate_cover = st.checkbox(
        f"🎨 Generate AI cover image for {st.session_state.selected_field}",
        value=HF_TOKEN is not None,
        disabled=HF_TOKEN is None,
        help="Uses field-specific prompts for better results"
    )

with col_input2:
    st.subheader("Topics")
    raw_input = st.text_area(
        f"Enter your {st.session_state.selected_field.lower()} topics (one per line or comma separated): *",
        value=st.session_state.raw_input,
        height=200,
        placeholder=f"Example for {st.session_state.selected_field}:\nTopic 1\nTopic 2\nTopic 3\n\nOr: Topic 1, Topic 2, Topic 3"
    )
    
    col_btn1, col_btn2 = st.columns(2)
    with col_btn1:
        generate_clicked = st.button(
            f"🚀 Generate {st.session_state.selected_field} Book",
            type="primary",
            use_container_width=True,
            disabled=not GOOGLE_API_KEY or not book_name or not raw_input.strip()
        )
    with col_btn2:
        reset_clicked = st.button(
            "🧹 Reset",
            type="secondary",
            use_container_width=True
        )

# Update Session State
st.session_state.book_name = book_name
st.session_state.book_description = book_description
st.session_state.book_type = book_type
st.session_state.raw_input = raw_input

# Handle Reset
if reset_clicked:
    for key in ['generated', 'book_content', 'pdf_filename', 'generating', 'topics', 'cover_image_path']:
        if key in st.session_state:
            del st.session_state[key]
    for key in ['book_name', 'book_type', 'book_description', 'raw_input']:
        st.session_state[key] = ""
    st.rerun()

# Handle Generate
if generate_clicked:
    if not GOOGLE_API_KEY:
        st.error("Google API key not configured. Please set GOOGLE_API_KEY environment variable.")
        st.stop()
    
    if not book_name.strip():
        st.error("Please enter a book title")
        st.stop()
    
    if not raw_input.strip():
        st.error("Please enter at least one topic")
        st.stop()
    
    topics = clean_topics(raw_input)
    if not topics:
        st.error("No valid topics found. Please check your input.")
        st.stop()
    
    st.session_state.generating = True
    st.session_state.topics = topics
    st.session_state.book_name = book_name or f"{book_type} Guide"
    st.session_state.book_type = book_type
    st.session_state.book_description = book_description
    field = st.session_state.selected_field
    
    # Show field-specific generation info
    field_config = FIELD_CONFIGS[field]
    st.info(f"✨ Generating {field} content with specialized prompts...")
    
    # Generate cover image if requested
    cover_path = None
    if generate_cover and HF_TOKEN:
        with st.spinner(f"🎨 Generating {field}-themed cover image..."):
            # Show the image prompt being used
            image_prompt = generate_field_specific_image_prompt(field, book_name, book_type, book_description)
            with st.expander("📝 Image Prompt Used"):
                st.code(image_prompt, language="text")
            
            cover_path = generate_book_cover_simple(book_name, book_type, field, book_description)
            if cover_path:
                st.session_state.cover_image_path = cover_path
                st.success(f"{field_config['icon']} Cover image generated successfully!")
            else:
                st.warning("Could not generate cover image. Proceeding without cover.")
    
    st.rerun()

# Generation Process
if 'generating' in st.session_state and st.session_state.generating:
    topics = st.session_state.topics
    book_name = st.session_state.book_name
    book_type = st.session_state.book_type
    field = st.session_state.selected_field
    book_description = st.session_state.book_description
    cover_path = st.session_state.get('cover_image_path')
    field_config = FIELD_CONFIGS[field]
    
    # Show field banner
    st.markdown(f"""
    <div style="background-color: {field_config['color_scheme']}20; padding: 10px; border-radius: 8px; margin: 10px 0;">
        <h3 style="color: {field_config['color_scheme']}; margin: 0;">
            {field_config['icon']} Generating: {book_name} ({field})
        </h3>
    </div>
    """, unsafe_allow_html=True)
    
    if cover_path and os.path.exists(cover_path):
        col_img, col_info = st.columns([1, 2])
        with col_img:
            st.image(cover_path, caption=f"{field} Themed Cover", width=300)
        with col_info:
            st.info(f"**Field:** {field}")
            st.info(f"**Book Style:** {book_type}")
            st.info(f"**Cover Style:** Field-specific AI generation")
    
    st.subheader("📚 Selected Topics")
    for topic in topics:
        st.markdown(f"- {topic}")
    
    st.subheader(f"📝 Generating Your {book_type}")
    
    progress_bar = st.progress(0)
    status_text = st.empty()
    
    # Start book content with field-specific header
    book_content = f"{field_config['icon']} {book_name}\n{'='*50}\n"
    book_content += f"Field: {field}\n"
    book_content += f"Book Type: {book_type}\n"
    if book_description:
        book_content += f"Description: {book_description}\n"
    book_content += f"Generated with kiddoBookAi\n{'='*50}\n\n"
    
    for idx, topic in enumerate(topics, 1):
        status_text.text(f"Generating Chapter {idx}/{len(topics)}: {topic}")
        
        with st.expander(f"Chapter {idx}: {topic}", expanded=idx==1):
            # Show the prompt being used for this topic
            text_prompt = generate_field_specific_text_prompt(topic, book_type, field, book_name, book_description)
            with st.expander("🔍 View Generation Prompt"):
                st.code(text_prompt, language="text")
            
            explanation = explain_topic(topic, book_type, field, book_name, book_description)
            st.write(explanation)
            
            book_content += f"\n\n{'='*40}\nChapter {idx}: {topic}\n{'='*40}\n{explanation}\n"
        
        progress_bar.progress(idx / len(topics))
    
    # Generate PDF with field-specific styling
    pdf_filename = f"kiddoBookAi_{field.replace(' ', '_')}_{book_name.replace(' ', '_')[:30]}.pdf"
    generate_pdf(book_content, book_name, book_type, field, cover_path, pdf_filename)
    
    st.session_state.generated = True
    st.session_state.generating = False
    st.session_state.book_content = book_content
    st.session_state.pdf_filename = pdf_filename
    
    st.balloons()
    st.success(f"✅ {field} Book Generated Successfully!")
    st.rerun()

# Download Section
if 'generated' in st.session_state and st.session_state.generated:
    st.markdown("---")
    st.subheader("📥 Download Your Book")
    
    field = st.session_state.selected_field
    field_config = FIELD_CONFIGS[field]
    
    # Show book info with field styling
    col_info1, col_info2 = st.columns(2)
    
    with col_info1:
        st.markdown(f"""
        <div style="background-color: {field_config['color_scheme']}10; padding: 15px; border-radius: 10px;">
            <h4 style="color: {field_config['color_scheme']}; margin: 0 0 10px 0;">
                {field_config['icon']} Book Information
            </h4>
            <p><strong>Title:</strong> {st.session_state.book_name}</p>
            <p><strong>Field:</strong> {field}</p>
            <p><strong>Style:</strong> {st.session_state.book_type}</p>
            <p><strong>Chapters:</strong> {len(st.session_state.topics)}</p>
        </div>
        """, unsafe_allow_html=True)
    
    with col_info2:
        if st.session_state.get('cover_image_path') and os.path.exists(st.session_state.cover_image_path):
            st.image(st.session_state.cover_image_path, caption=f"{field} Themed Cover", width=200)
    
    # Download buttons
    col_d1, col_d2 = st.columns(2)
    
    with col_d1:
        if os.path.exists(st.session_state.pdf_filename):
            with open(st.session_state.pdf_filename, "rb") as pdf_file:
                pdf_bytes = pdf_file.read()
                st.download_button(
                    label=f"📥 Download {field} PDF",
                    data=pdf_bytes,
                    file_name=st.session_state.pdf_filename,
                    mime="application/pdf",
                    use_container_width=True
                )
    
    with col_d2:
        st.download_button(
            label="📝 Download Text Only",
            data=st.session_state.book_content,
            file_name=st.session_state.pdf_filename.replace('.pdf', '.txt'),
            mime="text/plain",
            use_container_width=True
        )
    
    # Stats with field-specific metrics
    st.subheader("📊 Book Statistics")
    col_s1, col_s2, col_s3, col_s4 = st.columns(4)
    with col_s1:
        st.metric("Field", field)
    with col_s2:
        st.metric("Chapters", len(st.session_state.topics))
    with col_s3:
        st.metric("Book Style", st.session_state.book_type)
    with col_s4:
        has_cover = "Yes" if st.session_state.get('cover_image_path') else "No"
        st.metric("AI Cover", has_cover)

# Footer
st.markdown("---")
st.markdown("<p style='text-align: center; color: #666;'>kiddoBookAi • Field-specific Book Generator • Gemini + Hugging Face</p>", unsafe_allow_html=True)