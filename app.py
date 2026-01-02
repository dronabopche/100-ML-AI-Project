import re
import streamlit as st
import google.generativeai as genai
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
import base64
from io import BytesIO

# ==================================================
# CONFIGURATION
# ==================================================
API_KEY = "AIzaSyCcAjw01pUOUbY7peiya0esEUVvxkvx12A"   # ⚠️ Replace securely
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

# ==================================================
# TOPIC NORMALIZATION
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

# ==================================================
# LLM INTERACTION
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

# ==================================================
# PDF GENERATION (WITHOUT LOGO)
# ==================================================
def generate_pdf(book_text: str, book_name: str = "Book", book_type: str = "Textbook", filename: str = "KiddoBookAI.pdf") -> None:
    c = canvas.Canvas(filename, pagesize=A4)
    width, height = A4

    margin_x, margin_y = 50, 50
    line_height = 14

    # Header (without logo)
    c.setFont("Helvetica-Bold", 18)
    c.setFillColor("#1E3A8A")
    c.drawString(margin_x, height - margin_y, f"KiddoBookAI Presents:")
    
    c.setFont("Helvetica-Bold", 16)
    c.setFillColor("#1E40AF")
    c.drawString(margin_x, height - margin_y - 25, f"{book_name}")
    
    c.setFont("Helvetica", 10)
    c.setFillColor("#4B5563")
    c.drawString(margin_x, height - margin_y - 45, f"Book Type: {book_type}")
    c.drawString(margin_x, height - margin_y - 60, "Generated with KiddoBookAI - AI Book Generator")
    
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

# ==================================================
# STREAMLIT UI (WITHOUT LOGO)
# ==================================================
st.set_page_config(
    page_title="KiddoBookAI",
    page_icon="📘",
    layout="wide"
)

# Clean CSS without logo styling
st.markdown("""
<style>
    /* Main container */
    .main-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 20px;
    }
    
    /* Header */
    .app-header {
        text-align: center;
        padding: 1.5rem 0;
        margin-bottom: 1.5rem;
        background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
        border-radius: 16px;
        border: 1px solid #bae6fd;
    }
    
    .app-title {
        font-size: 2.5rem;
        font-weight: 800;
        background: linear-gradient(90deg, #1e40af 0%, #3b82f6 50%, #60a5fa 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        margin: 0;
        text-shadow: 0 2px 4px rgba(30, 64, 175, 0.1);
    }
    
    .app-subtitle {
        font-size: 1rem;
        color: #4b5563;
        margin-top: 0.5rem;
        max-width: 600px;
        line-height: 1.5;
        margin-left: auto;
        margin-right: auto;
    }
    
    /* Input styling */
    .stTextInput input, .stTextArea textarea {
        border: 1px solid #d1d5db !important;
        border-radius: 10px !important;
        padding: 12px !important;
        font-size: 14px !important;
        background: #f9fafb !important;
    }
    
    .stTextInput input:focus, .stTextArea textarea:focus {
        border-color: #3b82f6 !important;
        box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1) !important;
        background: white !important;
        outline: none !important;
    }
    
    /* Button styling */
    .stButton > button {
        background: linear-gradient(90deg, #1e40af 0%, #3b82f6 100%) !important;
        color: white !important;
        border: none !important;
        border-radius: 10px !important;
        padding: 14px 28px !important;
        font-weight: 600 !important;
        font-size: 16px !important;
        transition: all 0.3s ease !important;
        width: 100% !important;
        box-shadow: 0 4px 12px rgba(30, 64, 175, 0.2) !important;
    }
    
    .stButton > button:hover {
        transform: translateY(-2px) !important;
        box-shadow: 0 8px 24px rgba(59, 130, 246, 0.3) !important;
    }
    
    .reset-btn {
        background: linear-gradient(90deg, #6b7280 0%, #9ca3af 100%) !important;
        box-shadow: 0 4px 12px rgba(107, 114, 128, 0.2) !important;
    }
    
    .reset-btn:hover {
        box-shadow: 0 8px 24px rgba(107, 114, 128, 0.3) !important;
    }
    
    /* Topic badges */
    .topic-badge {
        display: inline-block;
        background: linear-gradient(90deg, #dbeafe 0%, #bfdbfe 100%);
        color: #1e40af;
        padding: 8px 16px;
        border-radius: 20px;
        margin: 4px;
        font-size: 14px;
        font-weight: 500;
        border: 2px solid #93c5fd;
        box-shadow: 0 2px 6px rgba(147, 197, 253, 0.2);
    }
    
    /* Chapter content */
    .chapter-box {
        background: #f8fafc;
        border-radius: 10px;
        padding: 1.5rem;
        margin: 1rem 0;
        border-left: 5px solid #3b82f6;
        border: 1px solid #e5e7eb;
        font-size: 14px;
        line-height: 1.6;
    }
    
    /* Progress bar */
    .stProgress > div > div > div > div {
        background: linear-gradient(90deg, #1e40af 0%, #3b82f6 100%);
        border-radius: 10px;
        height: 10px !important;
    }
    
    /* Success message */
    .success-box {
        background: linear-gradient(135deg, #10b981 0%, #34d399 100%);
        color: white;
        padding: 1.5rem;
        border-radius: 12px;
        margin: 1.5rem 0;
        border: none;
        box-shadow: 0 8px 24px rgba(16, 185, 129, 0.3);
    }
    
    /* Download section */
    .download-box {
        background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
        padding: 1.5rem;
        border-radius: 12px;
        margin: 1.5rem 0;
        border: 2px solid #fbbf24;
        box-shadow: 0 4px 12px rgba(251, 191, 36, 0.2);
    }
    
    /* Hide Streamlit elements */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}
    .stDeployButton {display: none;}
    
    /* Custom select box */
    .stSelectbox > div > div {
        background: #f9fafb !important;
        border: 1px solid #d1d5db !important;
        border-radius: 10px !important;
        padding: 8px !important;
    }
    
    .stSelectbox select {
        font-size: 14px !important;
        color: #374151 !important;
    }
    
    /* Metrics styling */
    .stMetric {
        background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
        border-radius: 12px;
        padding: 1rem;
        border: 1px solid #bae6fd;
    }
    
    /* Columns spacing */
    .stColumn {
        padding: 0 10px;
    }
</style>
""", unsafe_allow_html=True)

# ==================================================
# APP HEADER (WITHOUT LOGO)
# ==================================================
st.markdown("""
<div class="main-container">
    <div class="app-header">
        <h1 class="app-title">📘 KiddoBookAI</h1>
        <p class="app-subtitle">Create professional, AI-generated educational books from your topics</p>
    </div>
</div>
""", unsafe_allow_html=True)

# ==================================================
# INITIALIZE SESSION STATE
# ==================================================
if 'generated' not in st.session_state:
    st.session_state.generated = False
if 'book_content' not in st.session_state:
    st.session_state.book_content = ""
if 'pdf_filename' not in st.session_state:
    st.session_state.pdf_filename = ""
if 'book_type' not in st.session_state:
    st.session_state.book_type = "Textbook"
if 'book_name' not in st.session_state:
    st.session_state.book_name = ""
if 'book_description' not in st.session_state:
    st.session_state.book_description = ""
if 'raw_input' not in st.session_state:
    st.session_state.raw_input = ""

# ==================================================
# MAIN CONTENT
# ==================================================
col1, col2 = st.columns([2, 1], gap="large")

with col1:
    # Book Details
    st.markdown("### 📖 Book Details")
    
    book_name = st.text_input(
        "Book Title",
        value=st.session_state.book_name,
        placeholder="e.g., The Complete Guide to Machine Learning",
        help="Enter a title for your book",
        key="book_name_input"
    )
    
    book_description = st.text_area(
        "Description (Optional)",
        value=st.session_state.book_description,
        height=100,
        placeholder="Describe what this book is about, who it's for, and what readers will learn...",
        help="Helps AI understand context better",
        key="book_description_input"
    )
    
    # Book Type
    st.markdown("### 🎯 Book Style")
    book_type = st.selectbox(
        "Select the type of book you want to create:",
        ["Textbook", "Exam-prep Notes", "Story-style Guide", "Research Manual", "Beginner's Handbook"],
        index=["Textbook", "Exam-prep Notes", "Story-style Guide", "Research Manual", "Beginner's Handbook"].index(
            st.session_state.book_type
        ) if st.session_state.book_type in ["Textbook", "Exam-prep Notes", "Story-style Guide", "Research Manual", "Beginner's Handbook"] else 0,
        help="Choose the style that best fits your needs",
        key="book_type_select"
    )
    
    # Topics Input
    st.markdown("### 📝 Enter Topics")
    raw_input = st.text_area(
        "Enter your topics (one per line or comma separated):",
        value=st.session_state.raw_input,
        height=150,
        placeholder="Example formats:\n• Machine Learning\n• Neural Networks\n• Deep Learning\n\nOr:\nPython Programming, Data Science, Web Development",
        help="List all topics you want in your book",
        key="raw_input_textarea"
    )

with col2:
    # Action Buttons
    st.markdown("### ⚡ Actions")
    
    # Generate Button
    generate_clicked = st.button(
        "🚀 Generate Book",
        type="primary",
        use_container_width=True,
        key="generate_btn",
        help="Click to generate your book"
    )
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    # Reset Button
    reset_clicked = st.button(
        "🔄 Reset All",
        type="secondary",
        use_container_width=True,
        key="reset_btn",
        help="Clear all inputs"
    )
    
    st.markdown("---")
    
    # About Section
    st.markdown("""
    ### 📚 About KiddoBookAI
    
    Create professional AI-generated books with branding.
    
    **Features:**
    - Multiple book styles
    - PDF export with clean formatting
    - User-friendly interface
    - All books include KiddoBookAI branding
    """)

# ==================================================
# UPDATE SESSION STATE WITH CURRENT VALUES
# ==================================================
if 'generating' not in st.session_state or not st.session_state.generating:
    st.session_state.book_name = book_name
    st.session_state.book_description = book_description
    st.session_state.book_type = book_type
    st.session_state.raw_input = raw_input

# ==================================================
# HANDLE BUTTON ACTIONS
# ==================================================

# Handle Reset
if reset_clicked:
    keys_to_reset = ['generated', 'book_content', 'pdf_filename', 'generating', 'topics']
    for key in keys_to_reset:
        if key in st.session_state:
            del st.session_state[key]
    
    st.session_state.book_name = ""
    st.session_state.book_description = ""
    st.session_state.book_type = "Textbook"
    st.session_state.raw_input = ""
    
    st.rerun()

# Handle Generate
if generate_clicked:
    if not raw_input.strip():
        st.error("❌ Please enter at least one topic")
        st.stop()
    
    topics = clean_topics(raw_input)
    if not topics:
        st.error("❌ No valid topics found. Please check your input.")
        st.stop()
    
    st.session_state.generating = True
    st.session_state.topics = topics
    st.session_state.book_name = book_name or f"{book_type} Guide"
    st.session_state.book_type = book_type
    st.session_state.book_description = book_description
    
    st.rerun()

# ==================================================
# GENERATION PROCESS
# ==================================================
if 'generating' in st.session_state and st.session_state.generating:
    topics = st.session_state.topics
    book_name = st.session_state.book_name
    book_type = st.session_state.book_type
    book_description = st.session_state.book_description
    
    # Show topics
    st.markdown("### ✅ Topics to Include")
    st.markdown("<div style='margin: 1rem 0;'>", unsafe_allow_html=True)
    
    cols = st.columns(4)
    for idx, topic in enumerate(topics):
        with cols[idx % 4]:
            st.markdown(f'<div class="topic-badge">📚 {topic[:20]}{"..." if len(topic) > 20 else ""}</div>', unsafe_allow_html=True)
    
    st.markdown("</div>", unsafe_allow_html=True)
    
    st.markdown(f"### 📖 Generating Your {book_type}")
    
    progress_bar = st.progress(0)
    status_text = st.empty()
    
    book_content = f"{book_name}\n{'='*50}\nBook Type: {book_type}\n"
    if book_description:
        book_content += f"Description: {book_description}\n"
    book_content += f"Generated with KiddoBookAI\n{'='*50}\n\n"
    
    for idx, topic in enumerate(topics, 1):
        status_text.text(f"📝 Generating Chapter {idx}/{len(topics)}: {topic}")
        
        with st.expander(f"**Chapter {idx}: {topic}**", expanded=(idx == 1)):
            explanation = explain_topic(topic, book_type, book_name, book_description)
            st.markdown(f'<div class="chapter-box">{explanation}</div>', unsafe_allow_html=True)
            
            book_content += f"\n\n{'='*40}\nChapter {idx}: {topic}\n{'='*40}\n{explanation}\n"
        
        progress_bar.progress(idx / len(topics))
    
    pdf_filename = f"KiddoBookAI_{book_name.replace(' ', '_')[:50]}.pdf"
    generate_pdf(book_content, book_name, book_type, pdf_filename)
    
    st.session_state.generated = True
    st.session_state.generating = False
    st.session_state.book_content = book_content
    st.session_state.pdf_filename = pdf_filename
    
    st.rerun()

# ==================================================
# DOWNLOAD SECTION (After Generation)
# ==================================================
if 'generated' in st.session_state and st.session_state.generated:
    st.markdown("""
    <div class="success-box">
        <div style="display: flex; align-items: center; gap: 15px; margin-bottom: 10px;">
            <div style="font-size: 2rem;">🎉</div>
            <div>
                <h3 style='color: white; margin: 0;'>Book Generated Successfully!</h3>
                <p style='color: #d1fae5; margin: 5px 0 0 0; font-size: 0.9rem;'>
                Your book is ready with KiddoBookAI branding
                </p>
            </div>
        </div>
        <p style='color: white; margin: 10px 0 0 0; font-size: 0.95rem;'>
        Your book <b>"{st.session_state.book_name}"</b> has been created with {len(st.session_state.topics) if 'topics' in st.session_state else 0} chapters.
        </p>
    </div>
    """, unsafe_allow_html=True)
    
    st.markdown('<div class="download-box">', unsafe_allow_html=True)
    st.markdown("### 📥 Download Your Book")
    
    col1, col2 = st.columns(2)
    
    with col1:
        with open(st.session_state.pdf_filename, "rb") as pdf_file:
            pdf_bytes = pdf_file.read()
            st.download_button(
                label="📄 Download PDF",
                data=pdf_bytes,
                file_name=st.session_state.pdf_filename,
                mime="application/pdf",
                use_container_width=True,
                key="download_pdf",
                help="Includes KiddoBookAI branding"
            )
    
    with col2:
        st.download_button(
            label="📝 Download Text Version",
            data=st.session_state.book_content,
            file_name=st.session_state.pdf_filename.replace('.pdf', '.txt'),
            mime="text/plain",
            use_container_width=True,
            key="download_text",
            help="Plain text format without formatting"
        )
    st.markdown('</div>', unsafe_allow_html=True)
    
    st.markdown("### 📊 Book Statistics")
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("📚 Chapters", len(st.session_state.topics) if 'topics' in st.session_state else 0)
    with col2:
        st.metric("🎯 Style", st.session_state.book_type)
    with col3:
        st.metric("🏢 Branded", "Yes")
    with col4:
        st.metric("📄 Format", "PDF/TXT")

# ==================================================
# FOOTER WITH KIDDOBOOKAI BRANDING
# ==================================================
st.markdown("---")
st.markdown("""
<div style="text-align: center; color: #6b7280; padding: 2rem 0 1rem 0;">
    <div style="display: inline-flex; align-items: center; justify-content: center; gap: 10px; margin-bottom: 10px; padding: 8px 20px; background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%); border-radius: 12px; border: 1px solid #bae6fd;">
        <div style="width: 24px; height: 24px; background: linear-gradient(90deg, #1e40af 0%, #3b82f6 100%); border-radius: 6px;"></div>
        <p style="margin: 0; font-weight: 700; color: #1e40af; font-size: 1.1rem;">KiddoBookAI</p>
        <div style="width: 24px; height: 24px; background: linear-gradient(90deg, #3b82f6 0%, #60a5fa 100%); border-radius: 6px;"></div>
    </div>
    <p style="margin: 10px 0 0 0; font-size: 0.9rem; color: #4b5563;">Professional AI Book Generation Platform</p>
    <p style="margin: 5px 0 0 0; font-size: 0.8rem; color: #9ca3af;">All generated books include KiddoBookAI branding • Made with ❤️</p>
</div>
""", unsafe_allow_html=True)