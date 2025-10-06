# insert_test_data_for_stu8853.py
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://anjana:ijvyAnVldjuaQZ0W@cluster0.sfm1e8w.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
DB_NAME = os.getenv("DB_NAME", "wellnessDB")

async def insert_test_data():
    client = AsyncIOMotorClient(MONGO_URI)
    db = client[DB_NAME]
    
    # Get today's date and previous days
    today = datetime.utcnow().date()
    
    # Create phone usage data for the last 5 days
    phone_usage = []
    for i in range(5):
        date = today - timedelta(days=i)
        phone_usage.append({
            "studentId": "STU8853",
            "date": datetime(date.year, date.month, date.day),
            "screenTime": 240 + (i * 30),  # Increasing screen time
            "nightUsage": 30 + (i * 10),   # Increasing night usage
            "appsUsed": [
                {"appName": "Google Classroom", "durationMinutes": 60 + (i * 10)},
                {"appName": "Instagram", "durationMinutes": 80 + (i * 5)},
                {"appName": "Khan Academy", "durationMinutes": 30 + (i * 5)}
            ]
        })
    
    # Insert phone usage data
    if phone_usage:
        result = await db["PhoneUsage"].insert_many(phone_usage)
        print(f"✅ Inserted {len(result.inserted_ids)} phone usage records for STU8853")
    
    # Check if student exists, if not create one
    student = await db["Students"].find_one({"UserID": "STU8853"})
    if not student:
        student_data = {
            "Admission No": "ADM8853",
            "Name": "Test Student",
            "dob": "2005-05-15",
            "UserID": "STU8853",
            "Password": "testpassword",
            "Class": "10"
        }
        result = await db["Students"].insert_one(student_data)
        print(f"✅ Created student record for STU8853")
    
    # Check if academic data exists, if not create some
    academic = await db["academics"].find_one({"studentId": "STU8853"})
    if not academic:
        academic_data = {
            "studentId": "STU8853",
            "subjects": [
                {"name": "Math", "mark": 75},
                {"name": "Science", "mark": 68},
                {"name": "English", "mark": 82}
            ],
            "studyHours": "4",
            "focusLevel": "6",
            "overallMark": 75,
            "createdAt": datetime.utcnow()
        }
        result = await db["academics"].insert_one(academic_data)
        print(f"✅ Created academic record for STU8853")
    
    client.close()
    print("✅ Test data insertion completed successfully")

if __name__ == "__main__":
    asyncio.run(insert_test_data())