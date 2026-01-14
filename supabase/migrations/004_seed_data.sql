-- Seed data for HireMeBuddy
-- Run this after 001 and 002 to populate initial data

-- =====================================================
-- SERVICE CATEGORIES
-- =====================================================

INSERT INTO service_categories (name, description, is_active) VALUES
('Plumbing', 'Water pipe installation, repair, and maintenance', true),
('Electrical', 'Electrical wiring, repair, and installations', true),
('Cleaning', 'Home and office cleaning services', true),
('Carpentry', 'Furniture making and wood work', true),
('Painting', 'Interior and exterior painting services', true),
('Gardening', 'Lawn care, landscaping, and garden maintenance', true),
('Mechanics', 'Vehicle repair and maintenance', true),
('Tutoring', 'Academic tutoring and teaching', true),
('Beauty & Hair', 'Hair styling, makeup, and beauty services', true),
('Catering', 'Event catering and food preparation', true),
('Photography', 'Event and portrait photography', true),
('IT Support', 'Computer repair and technical support', true),
('Tailoring', 'Clothing alterations and custom sewing', true),
('Security', 'Security guard and surveillance services', true),
('Moving', 'Furniture moving and relocation services', true);

-- =====================================================
-- DEMO ADMIN USER (Optional - for testing)
-- =====================================================
-- Note: You need to create this user in Supabase Auth first
-- Then update their profile role to 'admin'

-- Example (replace with actual user ID after creating in Supabase Auth):
-- UPDATE profiles SET role = 'admin' WHERE id = 'YOUR-ADMIN-USER-UUID';

-- =====================================================
-- Seed data complete!
-- =====================================================
