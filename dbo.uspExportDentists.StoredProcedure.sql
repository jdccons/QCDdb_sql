USE [QCDdataSQL2005_dev]
GO
/****** Object:  StoredProcedure [dbo].[uspExportDentists]    Script Date: 01/11/2016 21:18:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspExportDentists]
AS 
    DELETE FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import;

    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblDentists_Import
            ( DentKeyID, LName, FName, Address, Address2, City, State, Zipcode,
              Specialty, DentSchool, DentGradYr, DentAffilDate, DentCloseOff,
              Phone, DentSpecialPrc, DentBilingual, DentWebsite, SearchCity,
              ZipSearch, SpecSearch )
            SELECT
                DentKeyID, DentLast, DentFirst, DentStreet1, DentStreet2,
                DentCity, DentState, DentZip, DentSpecialty, DentSchool,
                DentGradYr, DentAffilDate, DentCloseMyOff, DentPhoneOffice,
                DentSpecialPrice, DentBilingual, DentWebsite,
                REPLACE(DentCity, ' ', '') AS SearchCity,
                LEFT(DentZip, 5) AS ZipSearch, DentSpecialty
            FROM
                tblDentist
            WHERE
                DentStatus = 'A';
                
    

-- add the latitude and longitude to the dentist's record
    UPDATE
        di
    SET di.Latitude = z.Latitude, di.Longitude = z.Longitude
    FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import di
        INNER JOIN [TRACENTRMTSRV].QCD.dbo.ProZip z
            ON di.ZipSearch = z.ZipCode;

-- add the description of the dentist's speciality to the dentist's record
    UPDATE
        di
    SET di.Specialty = ds.SpecialityDesc
    FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import di
        INNER JOIN tblDentistSpec ds
            ON di.Specialty = ds.SpecialtyID;

-- add new patient notice
    UPDATE
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import
    SET DentCloseOff = ( CASE WHEN DentCloseOff = '0'
                              THEN 'Accepting New Patients:  Yes'
                              ELSE CASE WHEN DentCloseOff = '1'
                                        THEN 'Accepting New Patients:  No'
                                        ELSE DentCloseOff
                                   END
                         END )
    FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import;

-- add special pricing notice
    UPDATE
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import
    SET DentSpecialPrc = ( CASE WHEN DentSpecialPrc = '1'
                                THEN 'Exception pricing on speciality services:  Yes *'
                                ELSE CASE WHEN DentSpecialPrc = '0'
                                          THEN 'Exception pricing on speciality services::  No *'
                                          ELSE DentSpecialPrc
                                     END
                           END )
    FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import;

-- add bi-lingual notice
    UPDATE
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import
    SET DentBilingual = ( CASE WHEN DentBilingual = '0' THEN 'Bi-Lingual:  No'
                               ELSE CASE WHEN DentBilingual = '1'
                                         THEN 'Bi-lingual:  Yes'
                                         ELSE DentBilingual
                                    END
                          END )
    FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists_Import;

-- purge data from production table
    DELETE FROM
        [TRACENTRMTSRV].QCD.dbo.tblDentists;

-- insert data into production table from temp table
    INSERT  INTO [TRACENTRMTSRV].QCD.dbo.tblDentists
            ( DentKeyID, LName, FName, Address, Address2, City, State, Zipcode,
              Specialty, DentSchool, DentGradYr, DentAffilDate, DentCloseOff,
              Phone, DentSpecialPrc, DentBilingual, DentWebsite, SearchCity,
              zipsearch, SpecSearch, Latitude, Longitude )
            SELECT
                DentKeyID, LName, FName, Address, Address2, City, State,
                Zipcode, Specialty, DentSchool, DentGradYr, DentAffilDate,
                DentCloseOff, Phone, DentSpecialPrc, DentBilingual,
                DentWebsite, SearchCity, zipsearch, SpecSearch, Latitude,
                Longitude
            FROM
                [TRACENTRMTSRV].QCD.dbo.tblDentists_Import;
GO
