-- 테이블 생성 ------------------------------------------------

CREATE TABLE Owner (
    ownerSsn VARCHAR(13) PRIMARY KEY,
    name VARCHAR(50),
    phone VARCHAR(20)
);

CREATE TABLE Farm (
    farmId INT AUTO_INCREMENT PRIMARY KEY,
    farmName VARCHAR(100),
    location VARCHAR(100),
    phone VARCHAR(20),
    ownerSsn VARCHAR(13),
    FOREIGN KEY (ownerSsn) REFERENCES Owner(ownerSsn)
);

CREATE TABLE Customer (
    customerId INT AUTO_INCREMENT PRIMARY KEY,
    password VARCHAR(100),
    address VARCHAR(200)
);

CREATE TABLE Item (
    itemId INT AUTO_INCREMENT PRIMARY KEY,
    itemName VARCHAR(100),
    itemRank VARCHAR(10),
    price INT,
    cultivationDate DATE,
    farmId INT,
    averageRating FLOAT DEFAULT 0,
    itemStock INT DEFAULT 0, -- New column
    FOREIGN KEY (farmId) REFERENCES Farm(farmId)
);

CREATE TABLE PreferRank (
    customerId INT,
    itemRank VARCHAR(10),
    PRIMARY KEY (customerId, itemRank),
    FOREIGN KEY (customerId) REFERENCES Customer(customerId)
);

CREATE TABLE `Order` (
    orderId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT,
    itemId INT,
    quantity INT,
    orderDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    deliveryAddress VARCHAR(200),
    orderStatus VARCHAR(30) DEFAULT 'ORDERED',
    FOREIGN KEY (customerId) REFERENCES Customer(customerId),
    FOREIGN KEY (itemId) REFERENCES Item(itemId)
);

CREATE TABLE Review (
    reviewId INT AUTO_INCREMENT PRIMARY KEY,
    customerId INT,
    itemId INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customerId) REFERENCES Customer(customerId),
    FOREIGN KEY (itemId) REFERENCES Item(itemId)
);

CREATE TABLE DefectReport (
    reportId INT AUTO_INCREMENT PRIMARY KEY,
    orderId INT,
    itemId INT,
    customerId INT,
    reason TEXT,
    imageUrl TEXT,
    reportedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE,
    refundAmount INT,
    FOREIGN KEY (orderId) REFERENCES `Order`(orderId),
    FOREIGN KEY (itemId) REFERENCES Item(itemId),
    FOREIGN KEY (customerId) REFERENCES Customer(customerId)
);

CREATE TABLE QualityInspection (
    inspectionId INT AUTO_INCREMENT PRIMARY KEY,
    itemId INT,
    farmId INT,
    inspectorName VARCHAR(100),
    inspectionDate DATE,
    inspectionResult VARCHAR(10),
    notes TEXT,
    FOREIGN KEY (itemId) REFERENCES Item(itemId),
    FOREIGN KEY (farmId) REFERENCES Farm(farmId)
);

CREATE TABLE HarvestLog (
    harvestId INT AUTO_INCREMENT PRIMARY KEY,
    itemId INT,
    farmId INT,
    quantityHarvested INT,
    harvestDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (itemId) REFERENCES Item(itemId),
    FOREIGN KEY (farmId) REFERENCES Farm(farmId)
);

