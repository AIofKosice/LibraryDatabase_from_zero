SELECT * FROM books
ORDER BY 1;
SELECT * FROM branch
ORDER BY 1;
SELECT * FROM employees
ORDER BY 1;
SELECT * FROM issued_status
ORDER BY 1;
SELECT * FROM return_status
ORDER BY 1;
SELECT * FROM members
ORDER BY 1;


-- Project TASK


-- ### 2. CRUD Operations


-- Task 1. Create a New Book Record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')




-- Task 2: Update an Existing Member's Address

UPDATE members 
SET member_address = 'Somewhere Over the Rainbow'
WHERE member_id = 'C101'

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.

DELETE FROM issued_status 
WHERE issued_id = 'IS104'

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT * FROM(SELECT issued_emp_id, COUNT(1) FROM issued_status
GROUP BY issued_emp_id)
WHERE count > 1

SELECT issued_emp_id, COUNT(1) FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(1) > 1

-- ### 3. CTAS (Create Table As Select)

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt

CREATE TABLE book_counts AS(
SELECT
	b.isbn,
	b.book_title,
	COUNT(ist.issued_id) as number_issued
FROM books b
JOIN issued_status AS ist 
on ist.issued_book_isbn = b.isbn
GROUP BY b.isbn
);
SELECT * FROM book_counts

-- ### 4. Data Analysis & Findings

-- Task 7. **Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Fantasy';

-- Task 8: Find Total Rental Income by Category:

SELECT category, SUM(rental_price) as rental_price FROM books
GROUP BY 1
ORDER BY 2 DESC

-- Task 9. **List Members Who Registered in the Last 600 Days**:

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE  - INTERVAL '600 days'

-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:

SELECT  e1.emp_ID, e1.emp_name, b.manager_id, e2.emp_name as manager_name
FROM employees e1
JOIN branch b ON e1.branch_id = b.branch_id
JOIN employees e2 ON e2.emp_id = b.manager_id


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold

CREATE TABLE top_expensive_books AS(
SELECT * FROM books
WHERE rental_price > 8)

-- Task 12: Retrieve the List of Books Not Yet Returned

CREATE TABLE not_returned_books AS(
SELECT ist.* FROM issued_status ist 
LEFT JOIN return_status r ON r.issued_id = ist.issued_id
WHERE return_id IS NULL
)

SELECT issued_book_name, COUNT(1) as how_many_times_issued FROM issued_status
GROUP BY issued_book_name
HAVING COUNT(1) > 1



--Task 13: Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue



CREATE TABLE overdue_books AS(
SELECT member_name, issued_book_name, issued_date, (CURRENT_DATE - issued_date) as days_overdue, return_date
FROM members m
JOIN issued_status ist ON m.member_id = ist.issued_member_id
LEFT JOIN return_status rst ON ist.issued_id = rst.issued_id
WHERE return_date IS NULL AND
(CURRENT_DATE - ist.issued_date) > 30
)


--Task 14: Update Book Status on Return
--Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).

CREATE TABLE availability_of_books AS(
WITH CTE AS(
SELECT * FROM books b
JOIN issued_status ist ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status rst on ist.issued_id = rst.issued_id
)
SELECT book_title, category, 
CASE WHEN return_date IS NOT NULL THEN 'Available'
ELSE 'Not available'
END AS Availability
FROM CTE
)

-- books which not in return_status
SELECT * FROM issued_status
WHERE issued_id NOT IN 
(SELECT issued_id FROM return_status)


INSERT INTO return_status(return_id, issued_id, return_book_name, return_date, return_book_isbn)
VALUES('RS119', 'IS121', 'The Shining', CURRENT_DATE, '978-0-385-33312-0')


CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
    
BEGIN

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

	INSERT INTO return_status(return_id, issued_id, return_date, return_book_name, return_book_isbn)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, v_book_name, v_isbn);

    RAISE NOTICE 'Thank you for returning the book: %', v_book_name;
    
END;
$$

CALL add_return_record()


SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

CALL add_return_records('RS138', 'IS135');





--Task 15: Branch Performance Report
--Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE Revenue_by_branch AS(
SELECT branch_id, COUNT(ist.issued_id) AS count_of_issued_books, COUNT(return_id) AS count_of_returned_books, SUM(rental_price) AS revenue FROM issued_status ist 
JOIN employees e ON e.emp_id = ist.issued_emp_id
LEFT JOIN return_status rst ON ist.issued_id = rst.issued_id
JOIN books b ON b.isbn = ist.issued_book_isbn
GROUP BY branch_id
ORDER BY 1
)




--Task 16: CTAS: Create a Table of Active Members
--Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 6 months.

CREATE TABLE active_members AS(
SELECT * FROM members
WHERE member_id IN ( SELECT issued_member_id FROM issued_status
WHERE issued_date >= CURRENT_DATE - INTERVAL '1.5 year')
)





--Task 17: Find Employees with the Most Book Issues Processed
--Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

CREATE TABLE top_employees AS (
SELECT e.emp_name, COUNT(issued_emp_id) number_books_processed, e.branch_id FROM issued_status
JOIN employees e ON e.emp_id = issued_status.issued_emp_id
GROUP BY 1, 3
ORDER BY 2 DESC
LIMIT 3
)







--Task 18: Stored Procedure
--Objective: Create a stored procedure to manage the status of books in a library system.
    --Description: Write a stored procedure that updates the status of a book based on its issuance or return. Specifically:
    --If a book is issued, the status should change to 'no'.
    --If a book is returned, the status should change to 'yes'.



CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
    v_status VARCHAR(10);
BEGIN
    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;

    ELSE
        RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %', p_issued_book_isbn;
    END IF;
END;
$$

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

--FISRT CALL
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');

--NOTICE:  Sorry to inform you the book you have requested is unavailable book_isbn: 978-0-553-29698-2
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');

CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-553-29698-2'

/*
Task 20: Create Table As Select (CTAS)
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each day's fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines
*/


SELECT * FROM books
ORDER BY 1;
SELECT * FROM branch
ORDER BY 1;
SELECT * FROM employees
ORDER BY 1;
SELECT * FROM issued_status
ORDER BY 1;
SELECT * FROM return_status
ORDER BY 2;
SELECT * FROM members
ORDER BY 1;





-- SELECT member_id, member_name, COUNT(ist.issued_id) AS "Number of overdue_books",
-- CASE WHEN (CURRENT_DATE - issued_date) > 30 THEN (COUNT(ist.issued_id) * (CURRENT_DATE - issued_date) * 0.5) 
-- ELSE 0
-- END AS Total_fines
-- FROM members m
-- JOIN issued_status ist ON m.member_id = ist.issued_member_id
-- LEFT JOIN return_status rst ON ist.issued_id = rst.issued_id
-- WHERE return_date IS NULL
-- GROUP BY 1, 2, 4


CREATE TABLE overdue_fines AS(
SELECT
    m.member_id,
    m.member_name,
    COUNT(ist.issued_id) AS num_books_issued,
    COUNT(CASE WHEN rst.return_id IS NULL AND CURRENT_DATE - ist.issued_date > 30 THEN 1 END) AS num_overdue_books,
    SUM(
        CASE 
            WHEN rst.return_id IS NULL AND CURRENT_DATE - ist.issued_date > 30
            THEN (CURRENT_DATE - ist.issued_date) * 0.5
            ELSE 0
        END
    ) AS total_fines
FROM members m
JOIN issued_status ist ON m.member_id = ist.issued_member_id
LEFT JOIN return_status rst ON ist.issued_id = rst.issued_id
GROUP BY m.member_id, m.member_name
)
