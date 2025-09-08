-- clinic_database.sql

-- Create Database
CREATE DATABASE IF NOT EXISTS clinic_management;
USE clinic_management;

-- Specialties Table
CREATE TABLE specialties (
    specialty_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Doctors Table
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    license_number VARCHAR(50) UNIQUE NOT NULL,
    specialty_id INT NOT NULL,
    years_of_experience INT,
    biography TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (specialty_id) REFERENCES specialties(specialty_id) ON DELETE RESTRICT,
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_experience_non_negative CHECK (years_of_experience >= 0)
);

-- Patients Table
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(15),
    blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    allergies TEXT,
    medical_conditions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_patient_email_format CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_age_reasonable CHECK (date_of_birth <= CURDATE() - INTERVAL 1 YEAR)
);

-- Clinic Locations Table
CREATE TABLE clinic_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    phone_number VARCHAR(15),
    email VARCHAR(100),
    operating_hours TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Doctor Schedule Table
CREATE TABLE doctor_schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    location_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    appointment_duration INT NOT NULL DEFAULT 30 COMMENT 'Duration in minutes',
    max_patients_per_day INT DEFAULT 20,
    is_available BOOLEAN DEFAULT TRUE,
    effective_date DATE NOT NULL,
    end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES clinic_locations(location_id) ON DELETE RESTRICT,
    CONSTRAINT chk_time_valid CHECK (start_time < end_time),
    CONSTRAINT chk_duration_valid CHECK (appointment_duration BETWEEN 15 AND 120),
    CONSTRAINT chk_max_patients_valid CHECK (max_patients_per_day BETWEEN 1 AND 100),
    CONSTRAINT uq_doctor_schedule UNIQUE (doctor_id, location_id, day_of_week, effective_date)
);

-- Appointments Table
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    location_id INT NOT NULL,
    schedule_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show') DEFAULT 'scheduled',
    reason_for_visit TEXT NOT NULL,
    symptoms TEXT,
    priority ENUM('routine', 'urgent', 'emergency') DEFAULT 'routine',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (location_id) REFERENCES clinic_locations(location_id) ON DELETE RESTRICT,
    FOREIGN KEY (schedule_id) REFERENCES doctor_schedule(schedule_id) ON DELETE RESTRICT,
    CONSTRAINT chk_appointment_time_valid CHECK (start_time < end_time),
    CONSTRAINT chk_appointment_future_date CHECK (appointment_date >= CURDATE()),
    CONSTRAINT uq_doctor_timeslot UNIQUE (doctor_id, appointment_date, start_time)
);

-- Medical Records Table
CREATE TABLE medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_id INT,
    diagnosis TEXT,
    prescription TEXT,
    treatment_notes TEXT,
    vital_signs JSON COMMENT 'Stores blood pressure, temperature, heart rate, etc.',
    follow_up_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL
);

-- Billing Table
CREATE TABLE billing (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    appointment_id INT,
    total_amount DECIMAL(10, 2) NOT NULL,
    insurance_coverage DECIMAL(10, 2) DEFAULT 0,
    patient_responsibility DECIMAL(10, 2) NOT NULL,
    payment_status ENUM('pending', 'partial', 'paid', 'insurance_processing') DEFAULT 'pending',
    billing_date DATE NOT NULL,
    due_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    CONSTRAINT chk_amounts_valid CHECK (total_amount >= 0 AND insurance_coverage >= 0 AND patient_responsibility >= 0),
    CONSTRAINT chk_due_date_valid CHECK (due_date >= billing_date)
);

-- Payments Table
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM('cash', 'credit_card', 'debit_card', 'insurance', 'bank_transfer') NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transaction_id VARCHAR(100),
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES billing(bill_id) ON DELETE CASCADE,
    CONSTRAINT chk_payment_amount_positive CHECK (amount > 0)
);

-- Staff Table (Receptionists, Nurses, etc.)
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    role ENUM('receptionist', 'nurse', 'administrator', 'technician') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_staff_email_format CHECK (email LIKE '%@%.%')
);

-- Audit Log Table
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (changed_by) REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Indexes for better performance
CREATE INDEX idx_doctors_specialty ON doctors(specialty_id);
CREATE INDEX idx_doctors_active ON doctors(is_active);
CREATE INDEX idx_patients_email ON patients(email);
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_billing_patient ON billing(patient_id);
CREATE INDEX idx_billing_status ON billing(payment_status);
CREATE INDEX idx_doctor_schedule_doctor ON doctor_schedule(doctor_id);
CREATE INDEX idx_doctor_schedule_available ON doctor_schedule(is_available);

-- Insert sample data
INSERT INTO specialties (name, description) VALUES
('Cardiology', 'Heart and cardiovascular system specialists'),
('Dermatology', 'Skin, hair, and nail specialists'),
('Pediatrics', 'Medical care for infants, children, and adolescents'),
('Orthopedics', 'Bones, joints, and musculoskeletal system specialists'),
('General Practice', 'Primary care and general medical services');

INSERT INTO doctors (first_name, last_name, email, phone_number, license_number, specialty_id, years_of_experience) VALUES
('Sarah', 'Johnson', 's.johnson@clinic.com', '555-0101', 'MED123456', 1, 12),
('Michael', 'Chen', 'm.chen@clinic.com', '555-0102', 'MED123457', 2, 8),
('Emily', 'Rodriguez', 'e.rodriguez@clinic.com', '555-0103', 'MED123458', 3, 15),
('David', 'Kim', 'd.kim@clinic.com', '555-0104', 'MED123459', 4, 10),
('Jennifer', 'Wilson', 'j.wilson@clinic.com', '555-0105', 'MED123460', 5, 20);

INSERT INTO clinic_locations (name, address, city, state, postal_code, phone_number, email, operating_hours) VALUES
('Main Clinic', '123 Healthcare Ave', 'Springfield', 'IL', '62701', '555-0200', 'main@clinic.com', 'Mon-Fri: 8:00 AM - 6:00 PM, Sat: 9:00 AM - 2:00 PM'),
('Westside Branch', '456 Medical Blvd', 'Springfield', 'IL', '62702', '555-0201', 'west@clinic.com', 'Mon-Fri: 9:00 AM - 5:00 PM');

INSERT INTO patients (first_name, last_name, email, phone_number, date_of_birth, gender, emergency_contact_name, emergency_contact_phone, blood_type, allergies) VALUES
('John', 'Doe', 'john.doe@email.com', '555-0301', '1985-03-15', 'Male', 'Jane Doe', '555-0302', 'O+', 'Penicillin'),
('Mary', 'Smith', 'mary.smith@email.com', '555-0303', '1990-07-22', 'Female', 'John Smith', '555-0304', 'A-', 'Shellfish, Latex'),
('Robert', 'Brown', 'robert.b@email.com', '555-0305', '1978-11-30', 'Male', 'Susan Brown', '555-0306', 'B+', 'None');

-- Create views for common queries
CREATE VIEW doctor_availability AS
SELECT 
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    s.name AS specialty,
    cl.name AS clinic_location,
    ds.day_of_week,
    ds.start_time,
    ds.end_time,
    ds.appointment_duration
FROM doctor_schedule ds
JOIN doctors d ON ds.doctor_id = d.doctor_id
JOIN specialties s ON d.specialty_id = s.specialty_id
JOIN clinic_locations cl ON ds.location_id = cl.location_id
WHERE ds.is_available = TRUE AND ds.effective_date <= CURDATE() 
AND (ds.end_date IS NULL OR ds.end_date >= CURDATE());

CREATE VIEW upcoming_appointments AS
SELECT 
    a.appointment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    s.name AS specialty,
    cl.name AS clinic_location,
    a.appointment_date,
    a.start_time,
    a.end_time,
    a.status,
    a.reason_for_visit
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN specialties s ON d.specialty_id = s.specialty_id
JOIN clinic_locations cl ON a.location_id = cl.location_id
WHERE a.appointment_date >= CURDATE()
ORDER BY a.appointment_date, a.start_time;

-- Create triggers for data integrity
DELIMITER //

CREATE TRIGGER before_appointment_insert
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE schedule_exists INT;
    
    -- Check if doctor has schedule for this day and time
    SELECT COUNT(*) INTO schedule_exists
    FROM doctor_schedule ds
    WHERE ds.doctor_id = NEW.doctor_id
    AND ds.location_id = NEW.location_id
    AND ds.day_of_week = DAYNAME(NEW.appointment_date)
    AND NEW.start_time BETWEEN ds.start_time AND ds.end_time
    AND ds.is_available = TRUE
    AND ds.effective_date <= NEW.appointment_date
    AND (ds.end_date IS NULL OR ds.end_date >= NEW.appointment_date);
    
    IF schedule_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Doctor is not available at the requested time';
    END IF;
END;

//

CREATE TRIGGER after_appointment_completed
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Automatically create a billing record
        INSERT INTO billing (patient_id, appointment_id, total_amount, insurance_coverage, patient_responsibility, billing_date, due_date)
        VALUES (
            NEW.patient_id,
            NEW.appointment_id,
            150.00, -- Example amount
            120.00, -- Example insurance coverage
            30.00,  -- Example patient responsibility
            CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL 30 DAY)
        );
    END IF;
END;

//

DELIMITER ;

-- Create stored procedures
DELIMITER //

CREATE PROCEDURE GetDoctorAppointments(IN doctor_id INT, IN start_date DATE, IN end_date DATE)
BEGIN
    SELECT 
        a.appointment_id,
        CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
        a.appointment_date,
        a.start_time,
        a.end_time,
        a.status,
        a.reason_for_visit
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.doctor_id = doctor_id
    AND a.appointment_date BETWEEN start_date AND end_date
    ORDER BY a.appointment_date, a.start_time;
END;

//

CREATE PROCEDURE CancelAppointment(IN appt_id INT, IN reason TEXT)
BEGIN
    UPDATE appointments 
    SET status = 'cancelled', 
        updated_at = CURRENT_TIMESTAMP
    WHERE appointment_id = appt_id;
    
    -- Log the cancellation (could be extended to add to a separate cancellations table)
    INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
    VALUES ('appointments', appt_id, 'UPDATE', 
            JSON_OBJECT('status', 'scheduled'), 
            JSON_OBJECT('status', 'cancelled', 'reason', reason));
END;

//

DELIMITER ;
