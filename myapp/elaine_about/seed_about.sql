-- Prose sections (left side)
INSERT INTO about_sections (slug, title, body, sort_order) VALUES
    ('about_title', 'Why this exists', 'ABCDE', 10);

-- Index guide items (right card)
INSERT INTO index_guide_items (label, description, sort_order) VALUES
    ('Map',   'Map page explained', 10),
    ('Score', 'Score explained', 20),
    ('State', 'state-specific page explained', 30),
    ('News',  'News page explained', 40);