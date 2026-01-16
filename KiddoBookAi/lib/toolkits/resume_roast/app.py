from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import PyPDF2
import io
import os
from datetime import datetime
import tempfile
from dotenv import load_dotenv
import json

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app, origins=["http://localhost:*", "http://127.0.0.1:*", "http://10.0.2.2:*", "http://192.168.*:*"])

# Configure Grok AI 
GROK_API_KEY = os.getenv('GROK_API_KEY')
GROK_API_URL = "https://api.x.ai/v1/chat/completions"

if not GROK_API_KEY:
    print("❌ ERROR: GROK_API_KEY environment variable is not set")
    exit(1)

def test_grok_connection():
    """Test if Grok API key is valid"""
    headers = {
        "Authorization": f"Bearer {GROK_API_KEY}",
        "Content-Type": "application/json"
    }
    
    test_payload = {
        "messages": [
            {"role": "user", "content": "Say 'OK' if you're working"}
        ],
        "model": "grok-2-1212",
        "temperature": 0.7,
        "max_tokens": 10
    }
    
    try:
        response = requests.post(GROK_API_URL, headers=headers, json=test_payload, timeout=10)
        if response.status_code == 200:
            print("✅ Grok AI configured successfully")
            return True
        else:
            print(f"❌ Grok API error: {response.status_code} - {response.text[:100]}")
            return False
    except Exception as e:
        print(f"❌ Failed to connect to Grok AI: {e}")
        return False

# Test connection on startup
if not test_grok_connection():
    print("⚠️  Warning: Grok AI connection failed. API calls may fail.")
    print("Continuing with server startup...")

def extract_text_from_pdf(pdf_bytes):
    """Extract text from PDF bytes"""
    try:
        with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as temp_file:
            temp_file.write(pdf_bytes)
            temp_file.flush()
            temp_file_path = temp_file.name
            
        with open(temp_file_path, 'rb') as pdf_file:
            pdf_reader = PyPDF2.PdfReader(pdf_file)
            text = ""
            for page in pdf_reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
            
            if not text.strip():
                return "Could not extract text from PDF. The file might be scanned or image-based."
            return text.strip()
    except Exception as e:
        return f"Error extracting text: {str(e)}"
    finally:
        # Clean up temporary file
        if 'temp_file_path' in locals() and os.path.exists(temp_file_path):
            os.unlink(temp_file_path)

def analyze_resume_with_grok(resume_text, section_name):
    """Analyze resume for a specific section using Grok AI"""
    
    section_prompts = {
        'Strengths & Achievements': """
        You are an expert resume analyzer. Analyze the following resume and provide specific feedback on strengths and achievements.
        Be constructive but honest. Look for:
        1. Quantifiable achievements (numbers, percentages, $ amounts)
        2. Strong action verbs
        3. Clear career progression
        4. Relevant skills and certifications
        5. Project impact and results
        
        Format the response as bullet points starting with ✅ for positives.
        Keep it concise but insightful (max 150 words).
        
        Resume:
        {resume_text}
        """,
        
        'Weaknesses & Gaps': """
        You are a brutally honest resume critic. Analyze the following resume and identify weaknesses, gaps, and areas for improvement.
        Be brutally honest but constructive. Look for:
        1. Weak action verbs (like 'worked on', 'responsible for', 'helped with')
        2. Missing quantifiable metrics
        3. Skills gaps for target roles
        4. Formatting issues
        5. Missing information (certifications, projects, education)
        6. Typos or grammatical errors
        7. Generic or vague statements
        
        Format the response as bullet points starting with ⚠️ for areas to improve.
        Provide specific suggestions for improvement (max 150 words).
        
        Resume:
        {resume_text}
        """,
        
        'ATS Optimization': """
        You are an ATS (Applicant Tracking System) expert. Analyze this resume for ATS optimization.
        Provide:
        1. ATS compatibility score out of 100 with brief explanation
        2. Keywords that are well-represented (mention 5-7)
        3. Important keywords that are missing (mention 5-7)
        4. Formatting issues that might affect ATS parsing
        5. Specific suggestions to improve ATS score by 10+ points
        
        Format clearly with sections for score, good keywords, missing keywords, and suggestions.
        Use emojis to make it visually clear. Keep it concise (max 150 words).
        
        Resume:
        {resume_text}
        """,
        
        'Industry-Specific Recommendations': """
        You are a career advisor with expertise across multiple industries. Provide industry-specific recommendations for improving this resume.
        Consider different target industries/roles and suggest:
        1. Industry-specific keywords to add (for 2-3 relevant industries)
        2. Certifications that would be valuable
        3. Project types to highlight or add
        4. Skills to emphasize for specific roles
        5. Formatting/style preferences for different industries
        
        Focus on 2-3 main industries that would be relevant based on the resume content.
        Make practical, actionable suggestions (max 150 words).
        
        Resume:
        {resume_text}
        """
    }
    
    prompt = section_prompts.get(section_name, "").format(resume_text=resume_text[:4000])
    
    headers = {
        "Authorization": f"Bearer {GROK_API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "messages": [
            {"role": "system", "content": "You are an expert resume analyst and career coach. Provide constructive, actionable feedback."},
            {"role": "user", "content": prompt}
        ],
        "model": "grok-beta",
        "temperature": 0.7,
        "max_tokens": 500,
        "top_p": 0.9
    }
    
    try:
        response = requests.post(GROK_API_URL, headers=headers, json=payload, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content'].strip()
            else:
                return f"⚠️ Unexpected response format from Grok API"
        elif response.status_code == 401:
            return "❌ Invalid Grok API key. Please check your API key configuration."
        elif response.status_code == 429:
            return "⚠️ Rate limit exceeded. Please try again later."
        elif response.status_code == 402:
            return "💰 Payment required. Please check your xAI account balance."
        else:
            return f"⚠️ Grok API error {response.status_code}: {response.text[:100]}"
            
    except requests.exceptions.Timeout:
        return "⏰ Request timeout. The API is taking too long to respond."
    except requests.exceptions.ConnectionError:
        return "🔌 Connection error. Please check your internet connection."
    except Exception as e:
        return f"⚠️ Error analyzing {section_name}: {str(e)[:100]}"

@app.route('/analyze-resume', methods=['POST'])
def analyze_resume():
    """API endpoint to analyze resume with Grok AI"""
    print(f"\n📥 Received analyze request at {datetime.now().strftime('%H:%M:%S')}")
    
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided', 'success': False}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({'error': 'No file selected', 'success': False}), 400
    
    # Check file size (5MB limit)
    file.seek(0, 2)  # Seek to end
    file_size = file.tell()  # Get file size
    file.seek(0)  # Reset file pointer
    
    if file_size > 5 * 1024 * 1024:
        return jsonify({'error': 'File size exceeds 5MB limit', 'success': False}), 400
    
    # Read file
    file_bytes = file.read()
    print(f"📄 Processing file: {file.filename} ({file_size} bytes)")
    
    # Extract text based on file type
    if file.filename.lower().endswith('.pdf'):
        print("🔍 Extracting text from PDF...")
        resume_text = extract_text_from_pdf(file_bytes)
    elif file.filename.lower().endswith('.txt'):
        try:
            resume_text = file_bytes.decode('utf-8', errors='ignore')
        except:
            resume_text = file_bytes.decode('latin-1', errors='ignore')
    elif file.filename.lower().endswith(('.doc', '.docx')):
        return jsonify({
            'error': 'DOC/DOCX files not fully supported. Please convert to PDF or TXT.',
            'success': False
        }), 400
    else:
        return jsonify({'error': 'Unsupported file format. Please upload PDF or TXT', 'success': False}), 400
    
    if not resume_text or len(resume_text.strip()) < 10:
        return jsonify({'error': 'Could not extract meaningful text from file', 'success': False}), 400
    
    print(f"✅ Extracted {len(resume_text)} characters of text")
    
    # Analyze in sections using Grok AI
    sections = {}
    section_names = [
        'Strengths & Achievements',
        'Weaknesses & Gaps',
        'ATS Optimization',
        'Industry-Specific Recommendations'
    ]
    
    print("🤖 Starting Grok AI analysis...")
    
    # Create a progress tracker
    progress = {
        'total': len(section_names),
        'completed': 0,
        'failed': 0
    }
    
    for section_name in section_names:
        print(f"   📊 Analyzing: {section_name}")
        try:
            analysis = analyze_resume_with_grok(resume_text, section_name)
            sections[section_name] = analysis
            progress['completed'] += 1
            print(f"   ✅ Completed: {section_name}")
        except Exception as e:
            sections[section_name] = f"Error analyzing this section: {str(e)[:100]}"
            progress['failed'] += 1
            print(f"   ❌ Failed: {section_name} - {str(e)[:50]}")
    
    print(f"🎉 Analysis complete! {progress['completed']}/{progress['total']} sections successful")
    
    # Calculate analysis quality
    successful_sections = sum(1 for v in sections.values() if not v.startswith(('❌', '⚠️', 'Error')))
    analysis_quality = "Good" if successful_sections >= 3 else "Partial" if successful_sections >= 1 else "Poor"
    
    return jsonify({
        'success': True,
        'sections': sections,
        'resume_preview': resume_text[:500] + '...' if len(resume_text) > 500 else resume_text,
        'analysis_date': datetime.now().isoformat(),
        'analysis_quality': analysis_quality,
        'file_info': {
            'name': file.filename,
            'size': file_size,
            'type': file.content_type
        },
        'ai_provider': 'Grok AI (xAI)'
    })

@app.route('/test', methods=['GET'])
def test():
    """Test endpoint to check if server and Grok AI are working"""
    headers = {
        "Authorization": f"Bearer {GROK_API_KEY}",
        "Content-Type": "application/json"
    }
    
    test_payload = {
        "messages": [
            {"role": "user", "content": "Say 'OK' if you're working properly"}
        ],
        "model": "grok-beta",
        "temperature": 0.7,
        "max_tokens": 20
    }
    
    try:
        response = requests.post(GROK_API_URL, headers=headers, json=test_payload, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            ai_response = result['choices'][0]['message']['content'] if 'choices' in result else 'No response'
            ai_status = f"✅ Grok AI working - Response: {ai_response}"
        else:
            ai_status = f"❌ Grok API error: {response.status_code}"
            
    except Exception as e:
        ai_status = f"❌ Grok AI connection error: {str(e)[:100]}"
    
    return jsonify({
        'status': 'Server is running',
        'timestamp': datetime.now().isoformat(),
        'ai_status': ai_status,
        'endpoints': {
            'POST /analyze-resume': 'Upload and analyze resume with Grok AI',
            'GET /test': 'Test server and AI connection',
            'GET /health': 'Health check',
            'GET /info': 'Server information'
        }
    })

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'Resume Roaster API with Grok AI',
        'ai_provider': 'xAI Grok'
    })

@app.route('/info', methods=['GET'])
def info():
    """Server information endpoint"""
    return jsonify({
        'name': 'Resume Roaster API',
        'version': '1.0.0',
        'ai_provider': 'Grok AI (xAI)',
        'features': [
            'PDF/TXT resume analysis',
            'Four-section AI feedback',
            'Grok AI integration',
            'Real-time analysis'
        ],
        'endpoints': [
            {'method': 'POST', 'path': '/analyze-resume', 'desc': 'Analyze resume'},
            {'method': 'GET', 'path': '/test', 'desc': 'Test connection'},
            {'method': 'GET', 'path': '/health', 'desc': 'Health check'},
            {'method': 'GET', 'path': '/info', 'desc': 'API information'}
        ]
    })

if __name__ == '__main__':
    print("\n" + "="*50)
    print("🚀 Starting Resume Roaster Backend with Grok AI")
    print("="*50)
    print(f"📁 Environment: {os.getenv('FLASK_ENV', 'development')}")
    print(f"🔗 Backend URL: http://127.0.0.1:5000")
    print(f"🤖 AI Provider: Grok AI (xAI)")
    print(f"🧪 Test endpoint: http://127.0.0.1:5000/test")
    print(f"💊 Health check: http://127.0.0.1:5000/health")
    print("="*50)
    print("📋 Available endpoints:")
    print("   POST /analyze-resume - Upload resume for Grok AI analysis")
    print("   GET  /test           - Test server and Grok AI connection")
    print("   GET  /health         - Health check")
    print("   GET  /info           - API information")
    print("="*50)
    
    # Test Grok connection
    print("\n🔌 Testing Grok AI connection...")
    if test_grok_connection():
        print("✅ Grok AI connection successful!")
    else:
        print("⚠️  Warning: Grok AI connection may not work properly")
        print("   Make sure GROK_API_KEY is set correctly in .env file")
        print("   Get your API key from: https://console.x.ai")
    
    port = int(os.environ.get('PORT', 5000))
    debug_mode = os.getenv('FLASK_ENV', 'development') == 'development'
    
    print(f"\n⚡ Server running on port {port}")
    print(f"🐛 Debug mode: {'ON' if debug_mode else 'OFF'}")
    print("📝 Logs will appear below...")
    print("="*50 + "\n")
    
    app.run(host='0.0.0.0', port=port, debug=debug_mode)