
--pour les constituants

-- extraction pour Statpro pour les performances
DECLARE @date_begin datetime, @date_end datetime
SET @date_begin = '01/05/2015'
SET @date_end = '29/05/2015'

declare @code char(12),@superCode char(12)
declare @selectIndex table ( code char(12), superIndex char(12))
insert into @selectIndex  VALUES ('BTS1TREU','BT11TREU')
insert into @selectIndex  VALUES ('BT5ATREU','BT5ATREU')
insert into @selectIndex  VALUES ('BT11TREU','BT11TREU')
insert into @selectIndex  VALUES ('BTS3TREU','BT11TREU')
insert into @selectIndex  VALUES ('BTS5TREU','BT11TREU')

select * from @selectIndex

create table #CONSTITUENTS ( IndexCode [nvarchar](12) NOT NULL, IndexDate datetime NOT NULL, ISIN [nvarchar](12) NOT NULL, [AssetId] [bigint] NOT NULL, Weight float, IndexTotal int)

DECLARE index_cursor SCROLL CURSOR FOR select code,superIndex from @selectIndex
open index_cursor
--FETCH NEXT FROM index_cursor INTO @code,@superCode

WHILE @date_begin <= @date_end
BEGIN
    WHILE @@FETCH_STATUS = 0
    BEGIN		
		print RTRIM(CONVERT(nvarchar(30),@date_begin,103) )+';'+RTRIM(@code)+';'+@superCode
		insert into #CONSTITUENTS 
		select IndexCode,IndexDate,ISIN,AssetId,MarketValue/MarketValueTotal as Weight, IndexTotal from  ref_holding.INDEX_LISTING (@code, @date_begin,'BARCLAYS_RETURN')
		FETCH NEXT FROM index_cursor INTO @code,@superCode
	END
	FETCH FIRST FROM index_cursor INTO @code,@superCode
    SELECT @date_begin = @date_begin + 1
    
END
CLOSE index_cursor
DEALLOCATE index_cursor


select c.IndexCode,c.IndexDate,c.ISIN,c.Weight,p.Yield_ChangePrice_1D_Value,p.Price--,c.IndexTotal
from #CONSTITUENTS as c 
left outer join ref_security.PRICE as p on p.Date = c.IndexDate and p.SecurityId = c.AssetId and p.Price_Source ='BARCLAYS'

select distinct  h.ISIN,a.FinancialInstrumentName, h.IndexDate, price.Debt_Sensitivity ,price.Debt_TTM,price.Debt_YTM_Rate/100 
from #CONSTITUENTS as h
left outer join [ref_security].ASSET as a on a.Id = h.AssetId
left outer join [ref_security].PRICE as price on price.Date = h.IndexDate and price.SecurityId = h.AssetId and price.Price_Source ='BARCLAYS'
order by IndexDate, h.ISIN


drop table #CONSTITUENTS