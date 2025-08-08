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

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Electronic devices and gadgets'),
    ('Books', 'Physical and digital books'),
    ('Clothing', 'Apparel and accessories'),
    ('Home & Garden', 'Home improvement and gardening supplies')
ON CONFLICT (name) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, description, price, category_id, stock_quantity, is_active) VALUES
    ('Laptop Computer', 'High-performance laptop for work and gaming', 999.99, 1, 50, true),
    ('Smartphone', 'Latest model smartphone with advanced features', 699.99, 1, 100, true),
    ('Programming Book', 'Learn advanced programming techniques', 49.99, 2, 25, true),
    ('T-Shirt', 'Comfortable cotton t-shirt', 19.99, 3, 200, true),
    ('Garden Tools Set', 'Complete set of gardening tools', 79.99, 4, 30, true)
ON CONFLICT DO NOTHING;

-- Display summary of created data
DO $$
BEGIN
    RAISE NOTICE 'Database initialization completed successfully!';
    RAISE NOTICE 'Created tables: categories, products';
    RAISE NOTICE 'Sample data inserted:';
    RAISE NOTICE '  - % categories', (SELECT COUNT(*) FROM categories);
    RAISE NOTICE '  - % products', (SELECT COUNT(*) FROM products);
END $$;
