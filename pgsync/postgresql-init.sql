-- PGSync Database Initialization Script
-- This script creates categories and products tables with sample data

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) CHECK (price >= 0),
    category_id INTEGER REFERENCES categories(id),
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Electronic devices and gadgets'),
    ('Books', 'Books and literature'),
    ('Clothing', 'Apparel and accessories'),
    ('Home & Garden', 'Home improvement and gardening supplies'),
    ('Sports', 'Sports equipment and accessories'),
    ('Health & Beauty', 'Health and beauty products')
ON CONFLICT (name) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, description, price, category_id, stock_quantity, is_active) VALUES
    ('MacBook Pro 16"', 'High-performance laptop for professionals', 2499.99, 1, 10, true),
    ('iPhone 14 Pro', 'Latest smartphone with advanced camera', 999.99, 1, 25, true),
    ('iPad Air', 'Lightweight tablet for everyday use', 599.99, 1, 15, true),
    ('Wireless Earbuds', 'Noise-cancelling Bluetooth earbuds', 199.99, 1, 50, true),
    ('Smart Watch', 'Fitness tracker with heart rate monitor', 299.99, 1, 30, true),
    ('Python Programming Book', 'Complete guide to Python programming', 49.99, 2, 50, true),
    ('JavaScript Cookbook', 'Recipes for modern web development', 39.99, 2, 30, true),
    ('Data Science Handbook', 'Essential guide to data science', 59.99, 2, 20, true),
    ('Machine Learning Guide', 'Introduction to machine learning', 45.99, 2, 25, true),
    ('Cotton T-Shirt', 'Comfortable 100% cotton t-shirt', 19.99, 3, 100, true),
    ('Denim Jeans', 'Classic blue denim jeans', 59.99, 3, 75, true),
    ('Sneakers', 'Casual sneakers for everyday wear', 79.99, 3, 60, true),
    ('Hoodie', 'Warm hooded sweatshirt', 39.99, 3, 40, true),
    ('Garden Hose', '50ft expandable garden hose', 29.99, 4, 20, true),
    ('Plant Pot Set', 'Set of 3 ceramic plant pots', 24.99, 4, 35, true),
    ('Lawn Mower', 'Electric lawn mower for small yards', 199.99, 4, 8, true),
    ('Tennis Racket', 'Professional tennis racket', 149.99, 5, 15, true),
    ('Yoga Mat', 'Non-slip exercise yoga mat', 24.99, 5, 40, true),
    ('Running Shoes', 'Lightweight running shoes', 89.99, 5, 45, true),
    ('Basketball', 'Official size basketball', 29.99, 5, 25, true),
    ('Face Moisturizer', 'Hydrating face moisturizer', 15.99, 6, 60, true),
    ('Shampoo', 'Organic shampoo for all hair types', 12.99, 6, 80, true),
    ('Vitamin C Serum', 'Anti-aging vitamin C serum', 25.99, 6, 45, true),
    ('Electric Toothbrush', 'Rechargeable electric toothbrush', 79.99, 6, 20, true)
ON CONFLICT DO NOTHING;

-- Create trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updating timestamps
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Display summary of created data
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully!';
    RAISE NOTICE 'Created tables: categories, products';
    RAISE NOTICE 'Sample data inserted:';
    RAISE NOTICE '  - % categories', (SELECT COUNT(*) FROM categories);
    RAISE NOTICE '  - % products', (SELECT COUNT(*) FROM products);
END $$;
