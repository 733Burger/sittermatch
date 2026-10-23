-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: localhost    Database: sittermatch_db
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bookings`
--

DROP TABLE IF EXISTS `bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `listing_id` int NOT NULL,
  `sitter_id` int NOT NULL,
  `booking_type` varchar(255) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_booking_listings_idx` (`listing_id`),
  KEY `fk_booking_sitters_idx` (`sitter_id`),
  KEY `idx_bookings_sitter_status_dates` (`sitter_id`,`status`,`start_date`,`end_date`),
  CONSTRAINT `fk_booking_listings` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_booking_sitters` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `homeowner_services`
--

DROP TABLE IF EXISTS `homeowner_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `homeowner_services` (
  `homeowner_id` int NOT NULL,
  `service_type` varchar(45) NOT NULL,
  PRIMARY KEY (`homeowner_id`,`service_type`),
  CONSTRAINT `fk_homeowner_services` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `homeowner_verifications`
--

DROP TABLE IF EXISTS `homeowner_verifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `homeowner_verifications` (
  `homeowner_id` int NOT NULL,
  `id_photo` mediumblob,
  `id_photo_type` varchar(10) DEFAULT NULL,
  `id_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `id_rejection_reason` varchar(255) DEFAULT NULL,
  `residence_address` varchar(255) DEFAULT NULL,
  `residence_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `residence_rejection_reason` varchar(255) DEFAULT NULL,
  `emergency_contact_name` varchar(100) DEFAULT NULL,
  `emergency_contact_phone_number` varchar(20) DEFAULT NULL,
  `emergency_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `emergency_rejection_reason` varchar(255) DEFAULT NULL,
  `overall_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `reviewed_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`homeowner_id`),
  KEY `reviewed_by` (`reviewed_by`),
  CONSTRAINT `homeowner_verifications_ibfk_1` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`) ON DELETE CASCADE,
  CONSTRAINT `homeowner_verifications_ibfk_2` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `homeowners`
--

DROP TABLE IF EXISTS `homeowners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `homeowners` (
  `id` int NOT NULL,
  `rating` double DEFAULT NULL,
  `total_reviews` int DEFAULT '0',
  `address` varchar(255) DEFAULT NULL,
  `is_verified` bit(1) DEFAULT NULL,
  `requirements` varchar(255) DEFAULT NULL,
  `suburb` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_homeowners_lat_lng` (`latitude`,`longitude`),
  CONSTRAINT `fk_homeowners_users` FOREIGN KEY (`id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `listing_pets`
--

DROP TABLE IF EXISTS `listing_pets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `listing_pets` (
  `listing_id` int NOT NULL,
  `pet_id` int NOT NULL,
  PRIMARY KEY (`listing_id`,`pet_id`),
  KEY `fk_listing_pets_pets` (`pet_id`),
  CONSTRAINT `fk_listing_pets_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_listing_pets_pets` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `listings`
--

DROP TABLE IF EXISTS `listings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `listings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `homeowner_id` int NOT NULL,
  `suburb` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `home_details` varchar(255) DEFAULT NULL,
  `exact_address` varchar(255) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  `status` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_listing_homeowner_idx` (`homeowner_id`),
  KEY `idx_listings_lat_lng` (`latitude`,`longitude`),
  CONSTRAINT `fk_listing_homeowner` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `sitter_id` int NOT NULL,
  `homeowner_id` int NOT NULL,
  `sent_by` varchar(255) NOT NULL,
  `message` varchar(255) DEFAULT NULL,
  `sent_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_message_sitter_idx` (`sitter_id`),
  KEY `fk_message_homeowner_idx` (`homeowner_id`),
  KEY `idx_messages_pair` (`sitter_id`,`homeowner_id`,`sent_at`),
  CONSTRAINT `fk_message_homeowner` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_message_sitter` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pet_reviews`
--

DROP TABLE IF EXISTS `pet_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pet_reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `pet_id` int NOT NULL,
  `rating` int NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_pet_review_booking_idx` (`booking_id`),
  KEY `fk_pet_review_pet_idx` (`pet_id`),
  CONSTRAINT `fk_pet_review_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
  CONSTRAINT `fk_pet_review_pet` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pets`
--

DROP TABLE IF EXISTS `pets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `homeowner_id` int NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `species` varchar(255) DEFAULT NULL,
  `breed` varchar(255) DEFAULT NULL,
  `age` int NOT NULL,
  `care_notes` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `behaviour_score` double DEFAULT NULL,
  `total_reviews` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_pet_homeowner_idx` (`homeowner_id`),
  CONSTRAINT `fk_pet_homeowner` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reviews`
--

DROP TABLE IF EXISTS `reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `booking_id` int NOT NULL,
  `sitter_id` int NOT NULL,
  `homeowner_id` int NOT NULL,
  `reviewed_by` varchar(255) NOT NULL,
  `rating` int NOT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `status` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_review_booking_idx` (`booking_id`),
  KEY `fk_review_sitter_idx` (`sitter_id`),
  KEY `fk_review_homeowner_idx` (`homeowner_id`),
  CONSTRAINT `fk_review_booking` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_review_homeowner` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_review_sitter` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `saved_sitters`
--

DROP TABLE IF EXISTS `saved_sitters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `saved_sitters` (
  `id` int NOT NULL AUTO_INCREMENT,
  `homeowner_id` int NOT NULL,
  `sitter_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UNIQUE_FAVORITE` (`homeowner_id`,`sitter_id`),
  KEY `sitter_id` (`sitter_id`),
  CONSTRAINT `saved_sitters_ibfk_1` FOREIGN KEY (`homeowner_id`) REFERENCES `homeowners` (`id`) ON DELETE CASCADE,
  CONSTRAINT `saved_sitters_ibfk_2` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sitter_checks`
--

DROP TABLE IF EXISTS `sitter_checks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sitter_checks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `id_photo` varchar(500) DEFAULT NULL,
  `references` text,
  `sitter_id` int NOT NULL,
  `status` varchar(20) NOT NULL,
  `type` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sitter_pet_preferences`
--

DROP TABLE IF EXISTS `sitter_pet_preferences`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sitter_pet_preferences` (
  `sitter_id` int NOT NULL,
  `pet_type` varchar(45) NOT NULL,
  PRIMARY KEY (`sitter_id`,`pet_type`),
  UNIQUE KEY `UKar40safg70i7wa6yu40v589` (`sitter_id`,`pet_type`),
  CONSTRAINT `fk_sitter_pet_preferences` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sitter_services`
--

DROP TABLE IF EXISTS `sitter_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sitter_services` (
  `sitter_id` int NOT NULL,
  `service_type` varchar(45) NOT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `duration_minutes` int DEFAULT NULL,
  PRIMARY KEY (`sitter_id`,`service_type`),
  UNIQUE KEY `UKqu9gpmbhhi671g6l7193akqbh` (`sitter_id`,`service_type`),
  UNIQUE KEY `UKk41j2sjxc82de1x3k3npbf2y2` (`sitter_id`,`duration_minutes`,`price`,`service_type`),
  CONSTRAINT `fk_sitter_services` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sitter_verifications`
--

DROP TABLE IF EXISTS `sitter_verifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sitter_verifications` (
  `sitter_id` int NOT NULL,
  `id_photo` mediumblob,
  `id_photo_type` varchar(10) DEFAULT NULL,
  `id_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `id_rejection_reason` varchar(255) DEFAULT NULL,
  `residence_address` varchar(255) DEFAULT NULL,
  `residence_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `residence_rejection_reason` varchar(255) DEFAULT NULL,
  `emergency_contact_name` varchar(100) DEFAULT NULL,
  `emergency_contact_phone_number` varchar(20) DEFAULT NULL,
  `emergency_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `emergency_rejection_reason` varchar(255) DEFAULT NULL,
  `overall_status` enum('INCOMPLETE','PENDING','APPROVED','REJECTED') NOT NULL DEFAULT 'INCOMPLETE',
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `reviewed_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`sitter_id`),
  KEY `reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_sitter_verification_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_sitter_verification_sitter` FOREIGN KEY (`sitter_id`) REFERENCES `sitters` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sitters`
--

DROP TABLE IF EXISTS `sitters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sitters` (
  `id` int NOT NULL,
  `experience` text,
  `day_rate` double DEFAULT NULL,
  `night_rate` double DEFAULT NULL,
  `rating` double DEFAULT NULL,
  `is_verified` bit(1) DEFAULT NULL,
  `total_reviews` int DEFAULT NULL,
  `suburb` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `service_area` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sitters_lat_lng` (`latitude`,`longitude`),
  CONSTRAINT `fk_sitters_users` FOREIGN KEY (`id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `profile_photo_url` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `active_role` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email_UNIQUE` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'sittermatch_db'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-23 17:40:32
