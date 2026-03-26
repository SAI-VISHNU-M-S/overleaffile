# --- AUTHENTICATION ---
@app.get("/", response_class=HTMLResponse)
async def home(request: Request):
    user_id = request.cookies.get("session_user")
    if user_id and user_id != "None":
        return RedirectResponse(url="/dashboard", status_code=303)
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/register")
async def register(data: dict, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == data['username']).first():
        raise HTTPException(status_code=400, detail="Username taken")
    # Store user with email
    new_user = User(username=data['username'], email=data.get('email'), password_hash=data['password'])
    db.add(new_user)
    db.commit()
    return {"msg": "Registration successful"}

@app.post("/login")
async def login(data: dict, response: Response, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == data['username'], User.password_hash == data['password']).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    response.set_cookie(key="session_user", value=str(user.id), httponly=True, samesite="lax")
    return {"msg": "Login successful"}

@app.get("/logout")
async def logout(response: Response):
    resp = RedirectResponse(url="/", status_code=303)
    resp.delete_cookie("session_user")
    return resp
