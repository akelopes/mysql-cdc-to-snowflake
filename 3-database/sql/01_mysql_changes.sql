-- Insert six users in three sentences
INSERT INTO
    users(
        NAME,
        email,
        password
    )
SELECT
    'Lara',
    CONCAT('lara', LEFT(uuid(), 4), '@email.com'),
    LEFT(uuid(), 25);
INSERT INTO
    users(
        NAME,
        email,
        password
    )
SELECT
    'Jackson',
    CONCAT('jackson', LEFT(uuid(), 4), '@email.com'),
    LEFT(uuid(), 25);
INSERT INTO
    users(
        NAME,
        email,
        password
    )
SELECT
    NAME,
    CONCAT(LOWER(NAME), LEFT(uuid(), 4), '@email.com'),
    LEFT(uuid(), 25)
FROM
    (
        SELECT
            'Hana' AS NAME
        UNION
        SELECT
            'Morgan'
        UNION
        SELECT
            'Willie'
        UNION
        SELECT
            'Bruce'
    ) t;
-- Update last two user passwords
UPDATE
    users SET password = LEFT(uuid(), 10)
ORDER BY
    id DESC
LIMIT
    2;
-- Update first user password
UPDATE
    users SET password = LEFT(uuid(), 5)
ORDER BY
    id
LIMIT
    1;
-- Delete last user
DELETE FROM
    users
ORDER BY
    id DESC
LIMIT
    1;
-- Show actual state
SELECT
    *
FROM
    users
ORDER BY
    id;
