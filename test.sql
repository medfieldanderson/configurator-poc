USE [MDMIntegration_UT]
GO
/****** Object:  StoredProcedure [directoryservice].[uspGetProviders_AHC]    Script Date: 3/8/2022 10:58:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* ******************************************************************************
* Procedure : uspGetProviders_AHC
* DateTime  : 2021/12
* Author    : JANDERSON
* Purpose   : Return AHC providers for Elastic Data Load
* *******************************************************************************/
--DROP PROCEDURE [directoryservice].[uspGetProviders_AHC]
ALTER PROCEDURE [directoryservice].[uspGetProviders_AHC]
    @PlanIdList VARCHAR(MAX),
	@ListSize INT,
	@include_Officenids BIT = 1,
	@include_Lobs BIT = 1
AS
BEGIN
    SET NOCOUNT ON	

	DECLARE @LineOfBusiness TABLE (
		[PlanNid] INT, 
		[UrlIdentifier] VARCHAR(100)
	)
	
	DECLARE @AccountOrgOfficeNids TABLE
	(
		[AccountOrganizationUUID] bigint,
		[OfficeNIDs] VARCHAR(MAX)
	)

	DECLARE @AccountOrgPlan TABLE
	(
		[AccountOrganizationUUID] bigint,
		[PlanNIDs] VARCHAR(MAX),
		[UrlIdentifiers] VARCHAR(MAX)
	)
	
	DECLARE @VendorIsFacility BIT = 0

	INSERT INTO @LineOfBusiness
	SELECT 
		CONVERT(INT, item),
		LOWER(p.UrlIdentifier)
	FROM 
		mdm.udfSplitString(@PlanIdList, ',')
		INNER JOIN mdm.tblPlan p ON p.PlanNID = CONVERT(INT, item)
	
	IF @include_Officenids = 1
		BEGIN
			;WITH AcctOrgOffice (AccountOrganizationUUID, OfficeNID) 
			AS
			(
				SELECT 
					ao.AccountOrganizationUUID,
					o.OfficeNID 
				FROM 
					@LineOfBusiness lob
				INNER JOIN 
					directoryservice.tblAccountOrganization ao 
					ON lob.PlanNid = ao.PlanNID
				INNER JOIN
					directoryservice.tblOfficeAccountOrg oao
					ON oao.AccountOrganizationUUID = ao.AccountOrganizationUUID
				INNER JOIN 
					directoryservice.tblOffice o
					ON o.OfficeUUID = oao.OfficeUUID
			)

			INSERT INTO 
				@AccountOrgOfficeNids
			SELECT 
				aoo.AccountOrganizationUUID
				,STUFF((SELECT DISTINCT 
							' ' + CONVERT(VARCHAR, OfficeNID) 
						FROM 
							AcctOrgOffice
						WHERE 
							AccountOrganizationUUID = aoo.AccountOrganizationUUID 
						FOR xml PATH (''))
						,1,1,'' ) AS OfficeNIDs
			FROM  
				AcctOrgOffice aoo
			GROUP BY 
				AccountOrganizationUUID
		END

		IF @include_Lobs = 1
		BEGIN
			;WITH AccountOrgLob (AccountOrganizationUUID, PlanNid, UrlIdentifier) AS 
			(
				SELECT DISTINCT 
					ao.AccountOrganizationUUID, ao.PlanNID, lob.UrlIdentifier
				FROM 
					@LineOfBusiness lob 
					INNER JOIN directoryservice.tblAccountOrganization ao on lob.PlanNid = ao.PlanNID
					--INNER JOIN directoryservice.tblOfficeAccountOrg oao on ao.AccountOrganizationUUID = oao.AccountOrganizationUUID
					--INNER JOIN directoryservice.tblOffice o on oao.OfficeUUID = o.OfficeUUID
			)

			INSERT INTO @AccountOrgPlan
			SELECT 
				aol.AccountOrganizationUUID
				, STUFF((SELECT DISTINCT 
							' ' + CONVERT(VARCHAR, PlanNid) 
						FROM 
							AccountOrgLob
						WHERE 
							AccountOrganizationUUID = aol.AccountOrganizationUUID 
								FOR xml PATH ('')),1,1,'' ) AS PlanNIDs
				, STUFF((SELECT DISTINCT 
							' ' + LOWER(CONVERT(VARCHAR, UrlIdentifier))
						FROM 
							AccountOrgLob
						WHERE 
							AccountOrganizationUUID = aol.AccountOrganizationUUID 
								FOR xml PATH ('')),1,1,'' ) AS UrlIdentifiers
			FROM AccountOrgLob aol
		END

	SELECT TOP (@ListSize)
		NULLIF(ap.PlanProviderId, '') AS  ProviderPin,
		NULLIF(ap.AlternateID, '') AS ProviderAlternateId,								
		NULLIF(LTRIM(RTRIM(p.Npi)), '') AS ProviderNpi,
		NULLIF(p.PractitionerPrefixName, '') AS ProviderPrefix,
		NULLIF(p.PractitionerFirstName, '') AS ProviderFirstName,
		NULLIF(p.PractitionerMiddleName, '') AS ProviderMiddleName,
		NULLIF(ISNULL(p.PractitionerLastName, p.organizationName), '') AS ProviderLastName,
		NULLIF(p.PractitionerLastName, '') AS ProviderLastNameIndividual,
		NULLIF(p.PractitionerSuffixName, '') AS ProviderSuffix,
		p.IsIndividual AS ProviderIsIndividual,
		ap.IsPcp AS ProviderIsPcp,
		ap.IsSpecialist AS ProviderIsSpecialist,
		ISNULL(ap.IsPar,0) as ProviderIsPar,	
		NULLIF(ao.AccountNumber,'') AS vendorAccountNumber,
		NULLIF(ao.AlternateID,'') AS VendorAlternateId,
		NULLIF(ao.GroupNpi,'') AS VendorNpi,
		NULLIF(ao.TaxIDStr,'') AS VendorTaxId,
		NULLIF(LTRIM(RTRIM(ao.AccountName)), '') AS VendorName,
		NULLIF(addr.Line1, '') AS VendorAddressLine1,
		NULLIF(LTRIM(RTRIM(addr.Line2)), '') AS VendorAddressLine2,
		NULLIF(LTRIM(RTRIM(addr.City)), '') AS VendorCity,
		NULLIF(LTRIM(RTRIM(addr.[State])), '') AS VendorState,
		NULLIF(LTRIM(RTRIM(addr.ZipCode
							+ CASE
								WHEN ISNULL(addr.ZipCodeExtension, '') <> '' AND LEN(addr.ZipCodeExtension) = 4
								THEN '-' + addr.ZipCodeExtension
								ELSE ''
							END)), '') AS VendorZipCode,
		NULLIF(LTRIM(RTRIM(ao.Phone1Number)), '') AS VendorPhoneNumber1,
		NULLIF(LTRIM(RTRIM(ao.Phone1Extension)), '') AS VendorExtension1,
		NULLIF(LTRIM(RTRIM(ao.Phone2Number)), '') AS VendorPhoneNumber2,
		NULLIF(LTRIM(RTRIM(ao.Phone2Extension)), '') AS VendorExtension2,
		NULLIF(LTRIM(RTRIM(ao.Phone3Number)), '') AS VendorPhoneNumber3,
		NULLIF(LTRIM(RTRIM(ao.Phone3Extension)), '') AS VendorExtension3,
		@VendorIsFacility AS VendorIsFacility,	
		
		sp.SpecialtyCode AS VendorSpecialtyCode,
		'plan' AS VendorSpecialtyVocabulary,
		'' AS VendorSpecialtyLevel,
		sp.SpecialtyCode AS ProviderSpecialtyCode1,
		'plan' AS ProviderSpecialtyVocabulary1,
		'' AS ProviderSpecialtyLevel1,
		NULL AS ProviderSpecialtyCode2,
		NULL AS ProviderSpecialtyVocabulary2,
		NULL AS ProviderSpecialtyLevel2,
		--FORMAT(ISNULL(ao.AccountOrganizationStartDTM, {ts '1899-01-01 00:00:00'}),'yyyyMMdd') AS StartDate,
		--FORMAT(ISNULL(ao.AccountOrganizationEndDTM, {ts '2139-12-31 00:00:00'}),'yyyyMMdd') AS EndDate,
		ao.AccountOrganizationStartDTM AS StartDate,
		ao.AccountOrganizationEndDTM AS EndDate,
		aoo.OfficeNIDs AS ProviderOfficeNids,
		aop.UrlIdentifiers AS PlanList --Lobs
	FROM 
		[directoryservice].[tblPractitioner] p
	INNER JOIN
		[directoryservice].tblAccountProvider ap
		ON p.[PractitionerUUID] = ap.PractitionerUUID
	INNER JOIN [directoryservice].tblAccountOrganization ao
		ON ao.AccountOrganizationUUID = ap.AccountOrganizationUUID
	INNER JOIN [directoryservice].tblAddress addr
		ON ao.AddressUUID = addr.AddressUUID
	LEFT JOIN directoryservice.tblObjectSpecialty sp
		/* AHC-specific - must join directoryservice.tblObjectSpecialty on directoryservice.tblAccountProvider
		(NOT on directoryservice.tblAccountOrganization)
		*/
		ON sp.objectuuid = ap.AccountProviderUUID
	LEFT JOIN  @AccountOrgOfficeNids aoo
		ON aoo.AccountOrganizationUUID = ao.AccountOrganizationUUID
	LEFT JOIN @AccountOrgPlan aop
		ON aop.AccountOrganizationUUID = ao.AccountOrganizationUUID
	WHERE 
		ao.plannid in (select PlanNID from @LineOfBusiness)
		AND sp.SpecialtyType='Plan' 	
		
END

-- Unit tests
/*
	exec [directoryservice].[uspGetProviders_AHC] 
		@PlanIdList='467,1418',
		@ListSize=200,
		@include_Officenids=1,
		@include_Lobs=1

	exec [directoryservice].[uspGetProviders_AHC] 
		@PlanIdList='430,431,432,433,434,435,436,437,467,469,471,472,473,476,477,479,953,1396,1418,1419,1470,1472,1473,1474,1718,1719',
		@ListSize=2000000,
		@include_Officenids=1,
		@include_Lobs=1
*/

