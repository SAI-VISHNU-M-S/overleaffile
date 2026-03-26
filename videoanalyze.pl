@app.post("/analyze")
async def analyze(request: Request, file: UploadFile = File(...), db: Session = Depends(get_db)):
    user_id = request.cookies.get("session_user")
    if not user_id: raise HTTPException(status_code=401, detail="Unauthorized")

    fid = str(uuid.uuid4())
    in_p = str(BASE_DIR / "uploads" / f"{fid}_{file.filename}")
    out_p = str(OUTPUTS_DIR / f"out_{fid}.mp4")
    rep_p = str(REPORTS_DIR / f"rep_{fid}.pdf")
    
    os.makedirs(BASE_DIR / "uploads", exist_ok=True)
    with open(in_p, "wb") as f:
        shutil.copyfileobj(file.file, f)
    
    # Models A & C
    angle, feedback = process_video(in_p, out_p, rep_p)
    
    # Model B: OpenAI technical advice
    try:
        res = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are a cricket expert. Provide a 1-sentence technical tip."},
                {"role": "user", "content": f"Angle: {angle}, Feedback: {feedback}"}
            ]
        )
        feedback.append(res.choices[0].message.content)
    except:
        pass 

    new_report = AnalysisReport(
        user_id=int(user_id), 
        video_path=f"/outputs/out_{fid}.mp4", 
        report_path=f"/reports/rep_{fid}.pdf", 
        shot_type=feedback[0]
    )
    db.add(new_report)
    db.commit()

    return {"video_url": new_report.video_path, "report_url": new_report.report_path, "feedback": feedback}
