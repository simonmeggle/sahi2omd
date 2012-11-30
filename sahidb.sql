-- phpMyAdmin SQL Dump
-- version 3.4.5
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Erstellungszeit: 30. Nov 2012 um 11:06
-- Server Version: 5.5.16
-- PHP-Version: 5.3.8

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Datenbank: `sahi`
--
CREATE DATABASE `sahi` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `sahi`;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sahi_cases`
--

CREATE TABLE IF NOT EXISTS `sahi_cases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `result` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `guid` varchar(255) NOT NULL,
  `start` varchar(255) NOT NULL,
  `stop` varchar(255) NOT NULL,
  `warning` int(11) DEFAULT NULL,
  `critical` int(11) DEFAULT NULL,
  `browser` varchar(255) DEFAULT NULL,
  `lastpage` varchar(255) DEFAULT NULL,
  `screenshot` mediumblob,
  `sahi_suites_id` int(11) DEFAULT NULL,
  `duration` float NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `msg` varchar(2500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sahi_cases_sahi_suites` (`sahi_suites_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='Sahi Testcases' AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sahi_jobs`
--

CREATE TABLE IF NOT EXISTS `sahi_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `guid` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ind_guid` (`guid`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sahi_steps`
--

CREATE TABLE IF NOT EXISTS `sahi_steps` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `result` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `warning` int(11) DEFAULT NULL,
  `sahi_cases_id` int(11) NOT NULL,
  `duration` float NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `fk_sahi_steps_sahi_cases1` (`sahi_cases_id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='Sahi Testcases' AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Tabellenstruktur für Tabelle `sahi_suites`
--

CREATE TABLE IF NOT EXISTS `sahi_suites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `guid` varchar(255) NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COMMENT='Sahi Testcases' AUTO_INCREMENT=1 ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
