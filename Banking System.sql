-- Step 1: Create the Banking System database and use it
-- Creating and switching to the BankingSystem database ensures a dedicated workspace.
CREATE DATABASE BankingSystem;
USE BankingSystem;

-- Step 2: Create the AccountDetails table to store account information
-- AccountDetails holds account holder information, including balance and account type.
CREATE TABLE AccountDetails (
    AccountId INT PRIMARY KEY,                 -- Unique identifier for each account
    Name CHAR(30) NOT NULL,                    -- Account holder's name
    Age TINYINT CHECK(Age > 18),               -- Age of the account holder; must be > 18
    AccountType VARCHAR(20),                   -- Type of account (e.g., Savings, Current)
    CurrentBalance INT                         -- Current balance in the account
);

-- Insert sample data into AccountDetails
-- Populating the table with test data to verify structure and later functionality.
INSERT INTO AccountDetails VALUES
(1, 'Ram', 21, 'Savings', 1000),
(2, 'Sana', 23, 'Current', 500),
(3, 'Jhon', 27, 'Savings', 1000),
(4, 'Peter', 25, 'Savings', 1500),
(5, 'Kiran', 27, 'Current', 5200),
(6, 'Priya', 21, 'Savings', 5500),
(7, 'Varun', 28, 'Current', 500),
(8, 'Sonu', 24, 'Savings', 2500),
(9, 'Kumar', 29, 'Savings', 2000),
(10, 'Jathin', 22, 'Current', 5000),
(11, 'Suma', 23, 'Savings', 1500);

-- Step 3: Create the TransactionDetails table to store transaction logs
-- TransactionDetails logs account transactions, linking them to AccountDetails with a foreign key.
CREATE TABLE TransactionDetails (
    TransactionId INT PRIMARY KEY AUTO_INCREMENT,     -- Unique transaction identifier
    AccountId INT,                                    -- Account linked to the transaction
    TransactionType VARCHAR(10) CHECK(TransactionType IN ('Credit', 'Debit')), -- Transaction type
    TransactionAmount INT,                            -- Amount involved in the transaction
    TransactionTime DATETIME DEFAULT(NOW()),          -- Timestamp of the transaction
    FOREIGN KEY (AccountId) REFERENCES AccountDetails(AccountId) -- Foreign key constraint
);

-- Insert sample data into TransactionDetails
-- Initial data for testing transaction logging and trigger functionality.
INSERT INTO TransactionDetails(AccountId, TransactionType, TransactionAmount) VALUES
(1, 'Credit', 1000),
(1, 'Debit', 500),
(7, 'Credit', 1000),
(2, 'Credit', 1000);

-- Verify the inserted data
-- Check AccountDetails and TransactionDetails to ensure data integrity and correct insertion.
SELECT * FROM AccountDetails;
SELECT * FROM TransactionDetails;

-- Step 4: Create views for reporting and analysis
-- AccountsOfTransactions helps analyze accounts with transactions logged.
CREATE VIEW AccountsOfTransactions AS
SELECT * 
FROM AccountDetails 
WHERE AccountId IN (SELECT DISTINCT AccountId FROM TransactionDetails);

-- Check the AccountsOfTransactions view
SELECT * FROM AccountsOfTransactions;

-- Create a view for transactions of a specific account (e.g., AccountId = 1)
-- BankStatement simplifies fetching transactions for an individual account.
CREATE VIEW BankStatement AS
SELECT * 
FROM TransactionDetails 
WHERE AccountId = 1;

-- Retrieve data from the BankStatement view
SELECT * FROM BankStatement;

-- Create a view for transactions of another account (e.g., AccountId = 7)
-- BankStatement7 includes specific fields for clarity and ease of querying.
CREATE VIEW BankStatement7 AS
SELECT TransactionId, TransactionType, TransactionAmount, TransactionTime 
FROM TransactionDetails
WHERE AccountId = 7;

-- Retrieve data from the BankStatement7 view
SELECT * FROM BankStatement7;

-- Step 5: Create a dynamic stored procedure for BankStatement
-- This eliminates the need for creating one crore views, fetching data dynamically by AccountId.
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `BankStatement`(Par_AccountId INT)
BEGIN
    SELECT * FROM TransactionDetails
    WHERE AccountId = Par_AccountId;
END $$
DELIMITER ;

-- Step 5: Create stored procedures for reusable functionality
-- MiniStatement fetches account details and transactions for the last 6 months.
DELIMITER $$
CREATE PROCEDURE MiniStatement(Par_AccountId INT)
BEGIN
    -- Current date and time
    SELECT NOW() AS CurrentDateTime;

    -- Account ID and name
    SELECT Par_AccountId AS AccountId;
    SELECT Name FROM AccountDetails WHERE AccountId = Par_AccountId;

    -- Transactions from the last 6 months
    SELECT * FROM TransactionDetails 
    WHERE AccountId = Par_AccountId AND TIMESTAMPDIFF(MONTH, TransactionTime, NOW()) < 6;

    -- Current balance
    SELECT CurrentBalance FROM AccountDetails WHERE AccountId = Par_AccountId;
END$$
DELIMITER ;

-- Step 6: Create an error handler to manage exceptions
-- This stored procedure gracefully handles SQL errors and avoids abrupt failures.
DELIMITER $$
CREATE DEFINER=`root`@`localhost` PROCEDURE `ErrorHandler`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SELECT 'Something Went Wrong...Please try again !!!' AS Message;
    END;

    -- Sample queries within the error handler
    SELECT * FROM AcDetails;
    SELECT AccountId FROM TransonDetails;
END $$
DELIMITER ;


-- Step 6: Create a trigger to update account balances after a transaction
-- BalanceUpdater automatically updates balances in AccountDetails after a transaction.
-- Resetting tables and balances for clean testing of the trigger functionality.
TRUNCATE TransactionDetails; -- Clear previous transaction data
UPDATE AccountDetails SET CurrentBalance = 0; -- Reset account balances for testing

DELIMITER $$
CREATE TRIGGER BalanceUpdater
AFTER INSERT ON TransactionDetails
FOR EACH ROW
BEGIN
    DECLARE Var_AccountId INT;                  
    DECLARE Var_TransactionType VARCHAR(10);    
    DECLARE Var_TransactionAmount INT;          
    DECLARE Var_CurrentBalance INT;             

    -- Fetch details of the inserted transaction
    SET Var_AccountId = NEW.AccountId;
    SET Var_TransactionType = NEW.TransactionType;
    SET Var_TransactionAmount = NEW.TransactionAmount;

    -- Fetch the current balance of the account
    SELECT CurrentBalance INTO Var_CurrentBalance 
    FROM AccountDetails 
    WHERE AccountId = Var_AccountId;

    -- Update the account balance based on the transaction type
    IF Var_TransactionType = 'Credit' THEN
        UPDATE AccountDetails 
        SET CurrentBalance = Var_CurrentBalance + Var_TransactionAmount 
        WHERE AccountId = Var_AccountId;
    ELSE
        IF Var_TransactionAmount <= Var_CurrentBalance THEN
            UPDATE AccountDetails 
            SET CurrentBalance = Var_CurrentBalance - Var_TransactionAmount 
            WHERE AccountId = Var_AccountId;
        END IF;
    END IF;
END$$
DELIMITER ;

-- Step 7: Test the trigger by inserting transactions
-- Testing BalanceUpdater with different transaction scenarios.
-- Insert transactions individually into TransactionDetails
INSERT INTO TransactionDetails(AccountId, TransactionType, TransactionAmount) VALUES (1, 'Credit', 1000);
INSERT INTO TransactionDetails(AccountId, TransactionType, TransactionAmount) VALUES (2, 'Credit', 500);
INSERT INTO TransactionDetails(AccountId, TransactionType, TransactionAmount) VALUES (3, 'Debit', 500);
INSERT INTO TransactionDetails(AccountId, TransactionType, TransactionAmount) VALUES (1, 'Debit', 500);


-- Verify the updated data
-- Ensure the trigger updates AccountDetails balances correctly.
SELECT * FROM AccountDetails;
SELECT * FROM TransactionDetails;
