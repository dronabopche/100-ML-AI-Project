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
    model = genai.GenerativeModel("gemini-1.5-flash")
else:
    st.warning("Google API key not found. Please set GOOGLE_API_KEY environment variable.")

# Hugging Face Configuration
HF_FLUX_API_URL = "https://router.huggingface.co/replicate/v1/models/black-forest-labs/flux-2-dev/predictions"

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

# Hugging Face Image Generation Function
# ==================================================
def generate_book_cover_hf(book_name: str, book_type: str, book_description: str = ""):
    """Generate book cover using Hugging Face FLUX model"""
    
    if not HF_TOKEN:
        st.error("Hugging Face token not configured. Please set HF_TOKEN environment variable.")
        return None
    
    try:
        # Create a prompt for the cover
        prompt = f"Professional book cover design for '{book_name}', {book_type.lower()} style"
        if book_description:
            prompt += f", theme: {book_description[:50]}"
        
        prompt += ", clean design, minimalist, high quality, 4k, trending on artstation"
        
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
                                # Save the image
                                image_path = f"cover_{book_name.replace(' ', '_')[:30]}.png"
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
def generate_book_cover_simple(book_name: str, book_type: str, book_description: str = ""):
    """Simpler alternative using Hugging Face Inference API"""
    
    if not HF_TOKEN:
        return None
    
    try:
        # Create prompt
        prompt = f"Book cover for '{book_name}', {book_type.lower()} style, professional design"
        if book_description:
            prompt += f", theme: {book_description[:50]}"
        
        # Use a different Hugging Face endpoint that's more straightforward
        API_URL = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        
        payload = {
            "inputs": prompt,
            "parameters": {
                "negative_prompt": "ugly, blurry, text, watermark, signature",
                "num_inference_steps": 30,
                "guidance_scale": 7.5,
                "height": 512,
                "width": 512
            }
        }
        
        response = requests.post(API_URL, headers=headers, json=payload)
        
        if response.status_code == 200:
            # Save the image
            image_path = f"cover_{book_name.replace(' ', '_')[:30]}.png"
            with open(image_path, "wb") as f:
                f.write(response.content)
            return image_path
        else:
            st.error(f"Hugging Face Error: {response.status_code}")
            return None
            
    except Exception as e:
        st.error(f"Error: {str(e)}")
        return None

# LLM Interaction Layer (Google Gemini)
# ==================================================
def explain_topic(topic: str, book_type: str, book_name: str = "", book_description: str = "") -> str:
    """Generate content based on book type"""
    
    book_type_prompts = {
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
    
    book_type_info = book_type_prompts.get(book_type, book_type_prompts["Textbook"])
    
    prompt = f"""Write a chapter on "{topic}" for a {book_type.lower()}.

Book: {book_name if book_name else 'Unnamed Book'}
Description: {book_description if book_description else 'Not provided'}

Structure this chapter with:
{book_type_info['structure']}

Tone: {book_type_info['tone']}
Make it practical and educational."""
    
    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        return f"[Error generating content: {str(e)}]"

# Content Generator with Cover Image Support
# ==================================================
def generate_pdf(book_text: str, book_name: str = "Book", book_type: str = "Textbook", 
                 cover_image_path: str = None, filename: str = "kiddoBookAi.pdf") -> None:
    
    c = canvas.Canvas(filename, pagesize=A4)
    width, height = A4

    margin_x, margin_y = 50, 50
    line_height = 14
    
    # COVER PAGE (if image exists)
    if cover_image_path and os.path.exists(cover_image_path):
        try:
            # Create a cover page
            c.setFont("Helvetica-Bold", 24)
            c.setFillColorRGB(0.1, 0.1, 0.5)  # Dark blue
            c.drawString(margin_x, height - 150, book_name)
            
            c.setFont("Helvetica", 14)
            c.setFillColorRGB(0.3, 0.3, 0.3)
            c.drawString(margin_x, height - 200, f"A {book_type}")
            
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
    # Header
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor("#1E3A8A")
    c.drawString(margin_x, height - margin_y, f"kiddoBookAi Presents:")
    
    c.setFont("Helvetica-Bold", 16)
    c.setFillColor("#1E40AF")
    c.drawString(margin_x, height - margin_y - 25, f"{book_name}")
    
    c.setFont("Helvetica", 10)
    c.setFillColor("#4B5563")
    c.drawString(margin_x, height - margin_y - 45, f"Book Type: {book_type}")
    c.drawString(margin_x, height - margin_y - 60, "Generated with kiddoBookAi")
    
    # Content
    y = height - margin_y - 80
    c.setFont("Helvetica", 11)
    c.setFillColor("#111827")
    
    lines = book_text.split("\n")
    for line in lines:
        if y <= margin_y:
            c.showPage()
            y = height - margin_y
            c.setFont("Helvetica", 11)
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
for key in ['book_name', 'book_type', 'book_description', 'raw_input']:
    if key not in st.session_state:
        st.session_state[key] = ""

# Check API availability
api_status = {
    "Google Gemini": GOOGLE_API_KEY is not None,
    "Hugging Face": HF_TOKEN is not None
}

# App Header
st.title("📚 kiddoBookAi")
st.markdown("Create educational books with AI-generated covers")

# API Status Indicator
status_cols = st.columns(len(api_status))
for idx, (service, status) in enumerate(api_status.items()):
    with status_cols[idx]:
        if status:
            st.success(f"✅ {service}")
        else:
            st.warning(f"⚠️ {service}")

# Main Input Section
col1, col2 = st.columns(2)

with col1:
    st.subheader("Book Details")
    book_name = st.text_input(
        "Book Title *",
        value=st.session_state.book_name,
        placeholder="e.g., The Complete Guide to Machine Learning",
        help="Enter a title for your book"
    )
    
    book_description = st.text_area(
        "Description (Optional)",
        value=st.session_state.book_description,
        height=100,
        placeholder="Describe what this book is about... This helps generate a better cover image."
    )
    
    book_type = st.selectbox(
        "Book Style *",
        ["Textbook", "Exam-prep Notes", "Story-style Guide", "Research Manual", "Beginner's Handbook"],
        index=0
    )
    
    # Cover generation option
    generate_cover = st.checkbox(
        "🎨 Generate AI cover image with Hugging Face",
        value=HF_TOKEN is not None,
        disabled=HF_TOKEN is None,
        help="Requires Hugging Face API token"
    )

with col2:
    st.subheader("Topics")
    raw_input = st.text_area(
        "Enter your topics (one per line or comma separated): *",
        value=st.session_state.raw_input,
        height=200,
        placeholder="Example:\nMachine Learning\nArtificial Intelligence\nNeural Networks\n\nOr: Python, Data Science, Web Development"
    )
    
    col_btn1, col_btn2 = st.columns(2)
    with col_btn1:
        generate_clicked = st.button(
            "🚀 Generate Book",
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
    
    # Generate cover image if requested
    cover_path = None
    if generate_cover and HF_TOKEN:
        with st.spinner("🎨 Generating cover image with Hugging Face..."):
            cover_path = generate_book_cover_simple(book_name, book_type, book_description)
            if cover_path:
                st.session_state.cover_image_path = cover_path
                st.success("Cover image generated successfully!")
            else:
                st.warning("Could not generate cover image. Proceeding without cover.")
    
    st.rerun()

# Generation Process
if 'generating' in st.session_state and st.session_state.generating:
    topics = st.session_state.topics
    book_name = st.session_state.book_name
    book_type = st.session_state.book_type
    book_description = st.session_state.book_description
    cover_path = st.session_state.get('cover_image_path')
    
    if cover_path and os.path.exists(cover_path):
        st.image(cover_path, caption="Generated Book Cover", width=300)
    
    st.subheader("Selected Topics")
    for topic in topics:
        st.markdown(f"- {topic}")
    
    st.subheader(f"Generating Your {book_type}")
    
    progress_bar = st.progress(0)
    status_text = st.empty()
    
    book_content = f"{book_name}\n{'='*50}\nBook Type: {book_type}\n"
    if book_description:
        book_content += f"Description: {book_description}\n"
    book_content += f"Generated with kiddoBookAi\n{'='*50}\n\n"
    
    for idx, topic in enumerate(topics, 1):
        status_text.text(f"Generating Chapter {idx}/{len(topics)}: {topic}")
        
        with st.expander(f"Chapter {idx}: {topic}"):
            explanation = explain_topic(topic, book_type, book_name, book_description)
            st.write(explanation)
            
            book_content += f"\n\n{'='*40}\nChapter {idx}: {topic}\n{'='*40}\n{explanation}\n"
        
        progress_bar.progress(idx / len(topics))
    
    pdf_filename = f"kiddoBookAi_{book_name.replace(' ', '_')[:50]}.pdf"
    generate_pdf(book_content, book_name, book_type, cover_path, pdf_filename)
    
    st.session_state.generated = True
    st.session_state.generating = False
    st.session_state.book_content = book_content
    st.session_state.pdf_filename = pdf_filename
    
    st.balloons()
    st.success("✅ Book Generated Successfully!")
    st.rerun()

# Download Section
if 'generated' in st.session_state and st.session_state.generated:
    st.markdown("---")
    st.subheader("📥 Download Your Book")
    
    if st.session_state.get('cover_image_path') and os.path.exists(st.session_state.cover_image_path):
        col_cover, col_info = st.columns([1, 2])
        with col_cover:
            st.image(st.session_state.cover_image_path, caption="AI-Generated Cover", width=200)
        with col_info:
            st.info(f"**Book:** {st.session_state.book_name}")
            st.info(f"**Style:** {st.session_state.book_type}")
            st.info(f"**AI Services:** Gemini (text) + Hugging Face (cover)")
    
    col_d1, col_d2 = st.columns(2)
    
    with col_d1:
        if os.path.exists(st.session_state.pdf_filename):
            with open(st.session_state.pdf_filename, "rb") as pdf_file:
                pdf_bytes = pdf_file.read()
                st.download_button(
                    label="📥 Download PDF with Cover",
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
    
    # Stats
    st.subheader("Book Statistics")
    col_s1, col_s2, col_s3, col_s4 = st.columns(4)
    with col_s1:
        st.metric("Chapters", len(st.session_state.topics))
    with col_s2:
        st.metric("Style", st.session_state.book_type)
    with col_s3:
        has_cover = "Yes" if st.session_state.get('cover_image_path') else "No"
        st.metric("AI Cover", has_cover)
    with col_s4:
        st.metric("Formats", "2")

# Configuration Instructions
with st.expander("🔧 Setup Instructions"):
    st.markdown("""
    ### API Configuration
    
    1. **Google Gemini API:**
       - Get key from: https://makersuite.google.com/app/apikey
       - Set environment variable: `GOOGLE_API_KEY=your_key`
    
    2. **Hugging Face Token:**
       - Get token from: https://huggingface.co/settings/tokens
       - Set environment variable: `HF_TOKEN=your_token`
    
    ### For Streamlit Cloud Deployment:
    
    Add to `.streamlit/secrets.toml`:
    ```toml
    GOOGLE_API_KEY = "your_google_key"
    HF_TOKEN = "your_huggingface_token"
    ```
    
    ### Requirements (`requirements.txt`):
    ```txt
    streamlit>=1.28.0
    google-generativeai>=0.3.0
    requests>=2.31.0
    reportlab>=4.0.0
    Pillow>=10.0.0
    ```
    """)

# Footer
st.markdown("---")
st.markdown("<p style='text-align: center; color: #666;'>kiddoBookAi • Dual AI Book Generator • Gemini + Hugging Face</p>", unsafe_allow_html=True)