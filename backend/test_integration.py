import requests
import json
import os

BASE_URL = "http://localhost:5000/api"

print("1. Registering PMU Inspector...")
reg_res = requests.post(f"{BASE_URL}/auth/register", json={
    "username": "inspector_ram",
    "email": "ram@drishti.in",
    "password": "password123",
    "role": "PMU_Inspector"
})
print(reg_res.json())

print("\n2. Logging in...")
login_res = requests.post(f"{BASE_URL}/auth/login", json={
    "email": "ram@drishti.in",
    "password": "password123"
})
print(login_res.json())
token = login_res.json().get('access_token')

if not token:
    print("Login failed!")
    exit(1)

# We need an assignment and an institution to submit evidence for.
# Wait, let's create a dummy script inside docker to seed the db, since models are not exposed outside without app context.
