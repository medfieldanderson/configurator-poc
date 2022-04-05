select top 100 p.* from directoryservice.tblPractitioner p 
inner join directoryservice.tblAccountOrganization ao on p.PractitionerUUID = ao.AccountOrganizationUUID
where 
	NPI = '1770517468'






select p.* from directoryservice.tblPractitioner p where NPI = '1770517468'

select ao.* from directoryservice.tblAccountOrganization ao where GroupNPI = '1770517468'
	