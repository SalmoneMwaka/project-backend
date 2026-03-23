from fastapi import APIRouter, HTTPException
from App.database import SessionLocal
from App.models.user import User
from App.schemas.user import UserCreate, UserLogin
from passlib.context import CryptContext
import hashlib
router = APIRouter()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str):
    # Step 1: hash with SHA-256 (removes 72-byte limit issue)
    hashed = hashlib.sha256(password.encode()).hexdigest()
    
    # Step 2: hash with bcrypt
    return pwd_context.hash(hashed)


def verify_password(password: str, hashed: str):
    # Apply same SHA-256 before verifying
    hashed_input = hashlib.sha256(password.encode()).hexdigest()
    
    return pwd_context.verify(hashed_input, hashed)

@router.post("/signup")
def signup(data: UserCreate):
    db = SessionLocal()

    existing_user = db.query(User).filter(User.email == data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")

    new_user = User(
        email=data.email,
        password=hash_password(data.password)
    )

    db.add(new_user)
    db.commit()

    return {"message": "User created successfully"}


@router.post("/login")
def login(data: UserLogin):
    db = SessionLocal()

    user = db.query(User).filter(User.email == data.email).first()

    if not user:
        raise HTTPException(status_code=400, detail="User not found")

    if not verify_password(data.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid password")

    return {"message": "Login successful"}