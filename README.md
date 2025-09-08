# Clinic Booking System Database

## Overview
A comprehensive relational database system for managing clinic operations, including patient appointments, doctor schedules, medical records, and billing.

## Database Schema

### Core Tables
- **specialties**: Medical specialties (Cardiology, Dermatology, etc.)
- **doctors**: Healthcare providers with their specialties
- **patients**: Patient information and medical history
- **clinic_locations**: Physical clinic locations
- **doctor_schedule**: Availability and working hours of doctors
- **appointments**: Booking information and status
- **medical_records**: Patient treatment records
- **billing**: Financial transactions and insurance
- **payments**: Payment processing records

### Key Features
- Doctor availability management
- Appointment scheduling with conflict prevention
- Patient medical history tracking
- Billing and insurance processing
- Audit logging for data integrity
- Comprehensive constraints and validations

## Installation

1. **Prerequisites**
   - MySQL Server 8.0+
   - MySQL Workbench or command-line client

2. **Setup Database**
   ```bash
   mysql -u root -p < clinic_database.sql
