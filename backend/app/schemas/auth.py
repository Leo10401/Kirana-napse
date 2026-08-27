"""
Auth schemas — request/response models for authentication.
"""

from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    phone: str = Field(..., min_length=10, max_length=15, examples=["+919876543210"])
    password: str = Field(..., min_length=6, examples=["securepass"])
    name: str | None = Field(None, examples=["Ramesh Kumar"])


class LoginRequest(BaseModel):
    phone: str = Field(..., examples=["+919876543210"])
    password: str = Field(..., examples=["securepass"])


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    store_id: str | None = None


class UserResponse(BaseModel):
    id: str
    phone: str
    name: str | None
    is_active: bool

    model_config = {"from_attributes": True}
