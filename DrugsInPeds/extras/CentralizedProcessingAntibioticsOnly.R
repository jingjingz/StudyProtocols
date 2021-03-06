# Copyright 2016 Observational Health Data Sciences and Informatics
#
# This file is part of DrugsInPeds
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

denominatorType <- "persons" # denominatorType can be "persons" or "person time"

library(DrugsInPeds)
dbms <- "sql server"
server <- "RNDUSRDHIT06.jnj.com"
cdmDatabaseSchema <- "cdm_jmdc.dbo"
port <- NULL
cdmVersion <- "4"
password <- NULL
user <- NULL
oracleTempSchema <- NULL
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = password,
                                                                port = port)
folder <- "C:/home/Research/DrugsInPeds/results"
antibioticsFolder <- "C:/home/Research/DrugsInPeds/results/antibiotics"
if (!file.exists(antibioticsFolder)){
    dir.create(antibioticsFolder)
}

privateKey <- file.path(folder, "private.key")

dbs <- data.frame(name = c("AUSOM","CDARS","JMDC", "NHIRD", "PBS"), inpatient = c(TRUE, TRUE, TRUE, TRUE, FALSE), ambulatory = c(FALSE, FALSE, TRUE, TRUE, TRUE), stringsAsFactors = FALSE)
#dbs <- data.frame(name = c("AUSOM","JMDC", "PBS", "NHIRD"), inpatient = c(TRUE, TRUE, FALSE, TRUE), ambulatory = c(FALSE, TRUE, TRUE, TRUE), stringsAsFactors = FALSE)

classes <- c("Antibiotics")

### Decrypt, decompress, and generate tables and figures per DB ###
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    #if (dbs$name[i] != "PBS" & dbs$name[i] != "AUSOM") {
    #    try(OhdsiSharing::decryptAndDecompressFolder(file.path(dbFolder, "StudyResults.zip.enc"),
    #                                                 dbFolder,
    #                                                 privateKey))
    #}
    # createFiguresAndTables(connectionDetails = connectionDetails,
    #                        cdmDatabaseSchema = cdmDatabaseSchema,
    #                        oracleTempSchema = oracleTempSchema,
    #                        cdmVersion = cdmVersion,
    #                        folder = dbFolder)

    setwd(dbFolder)
    DrugsInPeds:::createTable3(denominatorType = "persons", drugsPerClass = 20)
}


### Combine table 1 across DBs ###
table1 <- data.frame()
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    dbTable1 <- read.csv(file.path(dbFolder, "table1.csv"), stringsAsFactors = FALSE)
    if (!dbs$inpatient[i]) {
        dbTable1[,4] <- NA
    }
    if (!dbs$ambulatory[i]) {
        dbTable1[,5] <- NA
    }
    emptyRow <- dbTable1[1,]
    emptyRow[1,] <- ""
    headerRow <- emptyRow
    headerRow[1,1] <- dbs$name[i]
    table1 <- rbind(table1, emptyRow, headerRow, dbTable1)
}
write.csv(table1, file.path(antibioticsFolder, "table1.csv"), row.names = FALSE, na = "")


### Combine tables 2a and 2b across DBs ###
table2a <- NULL
table2b <- NULL
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    if (dbs$inpatient[i]) {
        dbTable2a <- read.csv(file.path(dbFolder, "table2a.csv"), stringsAsFactors = FALSE)
        dbTable2a <- dbTable2a[dbTable2a$Class %in% classes, ]
        names(dbTable2a)[2:3] <- paste(names(dbTable2a)[2:3], dbs$name[i], sep="\n")
        if (is.null(table2a)){
            table2a <- dbTable2a
        } else {
            table2a <- merge(table2a, dbTable2a, all.x = TRUE)
        }
    }
    if (dbs$ambulatory[i]) {
        dbTable2b <- read.csv(file.path(dbFolder, "table2b.csv"), stringsAsFactors = FALSE)
        dbTable2b <- dbTable2b[dbTable2b$Class %in% classes, ]
        names(dbTable2b)[2:3] <- paste(names(dbTable2b)[2:3], dbs$name[i], sep="\n")
        if (is.null(table2b)){
            table2b <- dbTable2b
        } else {
            table2b <- merge(table2b, dbTable2b, all.x = TRUE)
        }
    }
}
table2a <- table2a[,order(names(table2a))]
table2b <- table2b[,order(names(table2b))]
write.csv(table2a, file.path(antibioticsFolder, "table2a.csv"), row.names = FALSE, na = "")
write.csv(table2b, file.path(antibioticsFolder, "table2b.csv"), row.names = FALSE, na = "")


### Combine tables 3a and 3b across DBs ###
table3a <- NULL
table3b <- NULL
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    if (dbs$inpatient[i]) {
        dbTable3a <- read.csv(file.path(dbFolder, "table3a.csv"), stringsAsFactors = FALSE)
        dbTable3a <- dbTable3a[dbTable3a$Class %in% classes, ]
        dbTable3a <- dbTable3a[order(dbTable3a$Class, -dbTable3a$UserPrevalence), ]
        names(dbTable3a)[2:3] <- paste(dbs$name[i], names(dbTable3a)[2:3], sep="\n")

        if (is.null(table3a)){
            table3a <- dbTable3a
        } else {
            table3a <- cbind(table3a, dbTable3a[, c(2,3)])
        }
    }
    dbFolder <- file.path(folder, dbs$name[i])
    if (dbs$ambulatory[i]) {
        dbTable3b <- read.csv(file.path(dbFolder, "table3b.csv"), stringsAsFactors = FALSE)
        dbTable3b <- dbTable3b[dbTable3b$Class %in% classes, ]
        dbTable3b <- dbTable3b[!is.na(dbTable3b$Class),]
        dbTable3b <- dbTable3b[order(dbTable3b$Class, -dbTable3b$UserPrevalence), ]
        names(dbTable3b)[2:3] <- paste(dbs$name[i], names(dbTable3b)[2:3], sep="\n")
        if (is.null(table3b)){
            table3b <- dbTable3b
        } else {
            table3b <- cbind(table3b, dbTable3b[, c(2,3)])
        }
    }
}
write.csv(table3a, file.path(antibioticsFolder, "table3a.csv"), row.names = FALSE, na = "")
write.csv(table3b, file.path(antibioticsFolder, "table3b.csv"), row.names = FALSE, na = "")


### Combine figures 1a and 1b across DBs ###
denominator <- data.frame()
numerator <- data.frame()
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    dbDenominator <- read.csv(file.path(dbFolder, "DenominatorByAgeGroup.csv"), stringsAsFactors = FALSE)
    dbNumerator <- read.csv(file.path(dbFolder, "NumeratorByAgeGroupByClass.csv"), stringsAsFactors = FALSE)
    dbNumerator <- dbNumerator[dbNumerator$conceptName %in% classes, ]
    dbDenominator$db <- dbs$name[i]
    dbNumerator$db <- dbs$name[i]
    if (!dbs$inpatient[i]) {
        dbNumerator <- dbNumerator[dbNumerator$inpatient == 0,]
    }
    if (!dbs$ambulatory[i]) {
        dbNumerator <- dbNumerator[dbNumerator$inpatient == 1,]
    }
    denominator <- rbind(denominator, dbDenominator)
    numerator <- rbind(numerator, dbNumerator)
}
numeratorInpatient <- numerator[numerator$inpatient == 1,]

data <- merge(denominator, numeratorInpatient)
if (denominatorType == "persons") {
    data$Prevalence <- data$personCount/(data$persons / 1000)
} else {
    data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
}
data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
ggplot2::ggplot(data, ggplot2::aes(x = ageGroup, y = Prevalence, group = db, color = db, fill = db)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                   strip.text.x = ggplot2::element_text(angle=-90))
ggplot2::ggsave(file.path(antibioticsFolder, "Figure1a.png"), width = 9, height = 7, dpi= 200)

numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
data <- merge(denominator, numeratorNotInpatient)
if (denominatorType == "persons") {
    data$Prevalence <- data$personCount/(data$persons / 1000)
} else {
    data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
}
data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
ggplot2::ggplot(data, ggplot2::aes(x = ageGroup, y = Prevalence, group = db, color = db, fill = db)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                   strip.text.x = ggplot2::element_text(angle=-90))
ggplot2::ggsave(file.path(antibioticsFolder, "Figure1b.png"), width = 9, height = 7, dpi= 200)


### Combine figures 2a and 2b across DBs ###
denominator <- data.frame()
numerator <- data.frame()
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    dbDenominator <- read.csv(file.path(dbFolder, "DenominatorByGender.csv"), stringsAsFactors = FALSE)
    dbNumerator <- read.csv(file.path(dbFolder, "NumeratorByGenderByClass.csv"), stringsAsFactors = FALSE)
    dbNumerator <- dbNumerator[dbNumerator$conceptName %in% classes, ]
    dbDenominator$db <- dbs$name[i]
    dbNumerator$db <- dbs$name[i]
    if (!dbs$inpatient[i]) {
        dbNumerator <- dbNumerator[dbNumerator$inpatient == 0,]
    }
    if (!dbs$ambulatory[i]) {
        dbNumerator <- dbNumerator[dbNumerator$inpatient == 1,]
    }
    denominator <- rbind(denominator, dbDenominator)
    numerator <- rbind(numerator, dbNumerator)
}
numeratorInpatient <- numerator[numerator$inpatient == 1,]

data <- merge(denominator, numeratorInpatient)
if (denominatorType == "persons") {
    data$Prevalence <- data$personCount/(data$persons / 1000)
} else {
    data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
}
data$Gender <- "Male"
data$Gender[data$genderConceptId == 8532] <- "Female"
ggplot2::ggplot(data, ggplot2::aes(x = Gender, y = Prevalence, group = db, color = db, fill = db)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                   strip.text.x = ggplot2::element_text(angle=-90))
ggplot2::ggsave(file.path(antibioticsFolder, "Figure2a.png"), width = 9, height = 9, dpi= 200)

numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
data <- merge(denominator, numeratorNotInpatient)
if (denominatorType == "persons") {
    data$Prevalence <- data$personCount/(data$persons / 1000)
} else {
    data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
}
data$Gender <- "Male"
data$Gender[data$genderConceptId == 8532] <- "Female"
ggplot2::ggplot(data, ggplot2::aes(x = Gender, y = Prevalence, group = db, color = db, fill = db)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                   strip.text.x = ggplot2::element_text(angle=-90))
ggplot2::ggsave(file.path(antibioticsFolder, "Figure2b.png"), width = 9, height = 9, dpi= 200)


### Combine figures 3a and 3b across DBs ###
denominator <- data.frame()
numerator <- data.frame()
for (i in 1:nrow(dbs)) {
    dbFolder <- file.path(folder, dbs$name[i])
    dbDenominator <- read.csv(file.path(dbFolder, "DenominatorByAgeGroupByYear.csv"), stringsAsFactors = FALSE)
    dbNumerator <- read.csv(file.path(dbFolder, "NumeratorByAgeGroupByYearByClass.csv"), stringsAsFactors = FALSE)
    dbNumerator <- dbNumerator[dbNumerator$conceptName %in% classes, ]
    dbDenominator$db <- dbs$name[i]
    dbNumerator$db <- dbs$name[i]
    dbDenominator <- dbDenominator[dbDenominator$calendarYear >= 2008 & dbDenominator$calendarYear <= 2013,]
    dbNumerator <- dbNumerator[dbNumerator$calendarYear >= 2008 & dbNumerator$calendarYear <= 2013,]
    if (!dbs$inpatient[i]) {
        dbNumerator <- dbNumerator[dbNumerator$inpatient == 0,]
    }
    if (!dbs$ambulatory[i]) {
        dbNumerator <- dbNumerator[dbNumerator$inpatient == 1,]
    }
    denominator <- rbind(denominator, dbDenominator)
    numerator <- rbind(numerator, dbNumerator)
}
numeratorInpatient <- numerator[numerator$inpatient == 1,]
data <- merge(denominator, numeratorInpatient)
if (denominatorType == "persons") {
    data$Prevalence <- data$personCount/(data$persons / 1000)
} else {
    data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
}
data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
ggplot2::ggplot(data, ggplot2::aes(x = calendarYear, y = Prevalence, group = db, color = db)) +
    ggplot2::geom_line() +
    ggplot2::facet_grid( ~ ageGroup, scales = "free") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                   strip.text.y = ggplot2::element_text(angle=0))
ggplot2::ggsave(file.path(antibioticsFolder, "Figure3a.png"), width = 12, height = 8, dpi= 200)

numeratorNotInpatient <- numerator[numerator$inpatient == 0,]
data <- merge(denominator, numeratorNotInpatient)
if (denominatorType == "persons") {
    data$Prevalence <- data$personCount/(data$persons / 1000)
} else {
    data$Prevalence <- data$personCount/(data$days / 365.25 / 1000)
}
data$ageGroup <- factor(data$ageGroup, levels = c("<2 years","2-11 years","12-18 years"))
ggplot2::ggplot(data, ggplot2::aes(x = calendarYear, y = Prevalence, group = db, color = db)) +
    ggplot2::geom_line() +
    ggplot2::facet_grid( ~ ageGroup, scales = "free") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle=-90),
                   strip.text.y = ggplot2::element_text(angle=0))
ggplot2::ggsave(file.path(antibioticsFolder, "Figure3b.png"), width = 12, height = 8, dpi= 200)

