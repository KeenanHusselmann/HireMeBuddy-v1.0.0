-- Add more ICT and other service categories

INSERT INTO service_categories (name, description, is_active) VALUES
('Web Development', 'Website design and development services', true),
('Mobile App Development', 'iOS and Android app development', true),
('Graphic Design', 'Logo design, branding, and digital graphics', true),
('Video Editing', 'Video production and editing services', true),
('Social Media Management', 'Social media marketing and content creation', true),
('Data Entry', 'Data entry and virtual assistant services', true),
('Bookkeeping', 'Accounting and financial record keeping', true),
('Consulting', 'Business and professional consulting services', true),
('Personal Training', 'Fitness and wellness training', true),
('Pet Care', 'Pet sitting, grooming, and walking services', true),
('Delivery Services', 'Package and food delivery', true),
('Event Planning', 'Event coordination and planning', true),
('Translation', 'Language translation and interpretation', true),
('Music Lessons', 'Music instruction and lessons', true),
('Home Repair', 'General home maintenance and repairs', true)
ON CONFLICT (name) DO NOTHING;
