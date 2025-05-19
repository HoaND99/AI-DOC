import os, io, time, requests
from flask import Flask, request, jsonify
from PyPDF2 import PdfReader
from docx import Document

app = Flask(__name__)

def extract_text(fstream, fname):
    ext = fname.rsplit('.',1)[-1].lower()
    data = fstream.read()
    if ext=='txt': return data.decode('utf-8',errors='ignore')
    if ext=='pdf':
        reader=PdfReader(io.BytesIO(data))
        return '\n'.join(p.extract_text() or '' for p in reader.pages)
    if ext=='docx':
        doc=Document(io.BytesIO(data))
        return '\n'.join(p.text for p in doc.paragraphs)
    return None

def call_gemini_api(prompt):
    key=os.getenv('GEMINI_API_KEY')
    model=os.getenv('GEMINI_MODEL','models/gemini-1.5-pro-latest')
    url=f"https://generativelanguage.googleapis.com/v1beta/{model}:generateContent?key={key}"
    payload={'contents':[{'parts':[{'text':prompt}]}]}
    backoff=1
    for _ in range(3):
        r=requests.post(url,json=payload)
        if r.status_code==429:
            time.sleep(backoff); backoff=min(backoff*2,10); continue
        r.raise_for_status()
        return r.json()['candidates'][0]['content']['parts'][0]['text']
    return call_text_bison_api(prompt)

def call_text_bison_api(prompt):
    key=os.getenv('GEMINI_API_KEY')
    url=f"https://generativelanguage.googleapis.com/v1beta/models/text-bison-001:generateText?key={key}"
    payload={'prompt':{'text':prompt},'temperature':0.7,'candidateCount':1}
    r=requests.post(url,json=payload); r.raise_for_status()
    return r.json()['candidates'][0]['output']

def summarize(text):
    if len(text) < 1500000:
        time.sleep(1)
        return call_gemini_api(f"Summarize this text:\n{text}")
    maxc=100000; pos=0; L=len(text); chunks=[]
    while pos<L:
        end=min(pos+maxc,L)
        nl=text.rfind('\n',pos,end)
        if nl>pos: end=nl
        chunks.append(text[pos:end].strip()); pos=end
    summ=[]
    for c in chunks:
        time.sleep(1); summ.append(call_gemini_api(f"Summarize this text:\n{c}"))
    comb="Combine these summaries into one coherent summary:\n\n"+'\n\n'.join(summ)
    time.sleep(1); return call_gemini_api(comb)

@app.route('/summarize',methods=['POST'])
def route_summarize():
    if 'file' not in request.files: return jsonify({'error':'no file part'}),400
    f=request.files['file']; text=extract_text(f.stream,f.filename)
    if text is None: return jsonify({'error':'unsupported file type'}),400
    try: out=summarize(text)
    except Exception as e: return jsonify({'error':str(e)}),503
    return jsonify({'summary':out})

if __name__=='__main__':
    app.run(host='0.0.0.0',port=int(os.getenv('PORT',8080)))
