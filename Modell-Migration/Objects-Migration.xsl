<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:lido="http://www.lido-schema.org"
    xmlns:easydb="https://schema.easydb.de/EASYDB/1.0/objects/" exclude-result-prefixes="xs"
    version="2.0">
    <xsl:output method="text" encoding="utf-8"/>

    <xsl:param name="version" select="M1.1"/>
    <!-- Version dieser XSLT-Transformation -->
    <xsl:param name="language" select="'all'"/>
    <!-- bevorzugte Sprache z.B. en-US/de-DE/all -->
    <xsl:param name="authoritydata" select="'links'"/>
    <!-- all/links -->
    <xsl:param name="creationid" select="'ubmz-17'"/>
    <!-- ubmz-17 -->
    <xsl:param name="productionid" select="'ubmz-14'"/>
    <!-- ubmz-14 -->
    <xsl:param name="acquisitionid" select="'ubmz-11'"/>
    <!-- ubmz-11 -->
    <xsl:param name="purchaseid" select="'ubmz-15'"/>
    <!-- ubmz-15 -->
    <xsl:param name="donationid" select="'ubmz-25'"/>
    <!-- ubmz-25 -->
    <xsl:param name="collectionid" select="'ubmz-24'"/>
    <!-- ubmz-24 -->
    <xsl:param name="findingid" select="'ubmz-12'"/>
    <!-- ubmz-12 -->
    <xsl:param name="typeassignmentid" select="'ubmz-29'"/>
    <!-- ubmz-29 -->
    <xsl:param name="trennung">";"</xsl:param>
    <xsl:param name="trennungimfeld" select="'&#13;'"/>
    <xsl:param name="eventreihenfolge" select="($creationid, $findingid, $acquisitionid, $purchaseid, $donationid, $typeassignmentid)"/>

    <!-- Der Schlüssel wird zum Deduplizieren der Events innerhalb eines Objekts gebraucht (Muenchscher Algorithmus) -->
    <xsl:key name="events" match="easydb:ubmz_event_id"
        use="concat(generate-id(ancestor::easydb:objekte), '.', .)"/>

    <!-- Hier geht's los -->
    <xsl:template match="/">
        <xsl:message>
            <xsl:value-of select="concat('Version ', $version)"/>
        </xsl:message>
        <xsl:message>Migrationstabelle...</xsl:message>
        <xsl:variable name="ereignisspalten" select="'objektgeschichte[].ereignis_typ#ubmz_event_id;Ereignistyp;objektgeschichte[].datum_ereignis;objektgeschichte[].datum_normiert_ereignis#from;objektgeschichte[].datum_normiert_ereignis#to;objektgeschichte[].unsicher_datum;objektgeschichte[].ort_ereignis#_system_object_id;Ort;objektgeschichte[].unsicher_ort;objektgeschichte[].personen_ereignis[].person_ereignis#_system_object_id;Person/Körperschaft;objektgeschichte[].personen_ereignis[].rolle_ereignis#_system_object_id;Rolle;objektgeschichte[].personen_ereignis[].unsicher;objektgeschichte[].bemerkung_ereignis;'"/>
        <xsl:text>_system_object_id;Objekttitel;</xsl:text><xsl:value-of select="$ereignisspalten"/><xsl:value-of select="$ereignisspalten"/><xsl:value-of select="$ereignisspalten"/><xsl:value-of select="$ereignisspalten"/>
        <xsl:element name="lido:lidoWrap">
            <xsl:apply-templates/>
        </xsl:element>
        <xsl:message>Migrationstabelle fertig</xsl:message>
    </xsl:template>

    <!-- Personen in Events -->
    <xsl:template name="person">
        <xsl:param name="person_node"/>
        <xsl:variable name="pk_node"
            select="$person_node/easydb:person_koerperschaft/easydb:personen_koerperschaften"/>
        <xsl:message>Person - <xsl:value-of select="($pk_node/easydb:_standard/easydb:*)[1]"
            /></xsl:message>
        <xsl:message>GND <xsl:value-of
                    select="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']"
                /></xsl:message>
         <xsl:value-of select="$pk_node/easydb:name"/>
        <!-- <xsl:value-of select="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']"/> -->
    </xsl:template>
 
    <!-- Personen-ID in Events -->
    <xsl:template name="personen-id">
        <xsl:param name="person_node"/>
        <xsl:variable name="pk_node"
            select="$person_node/easydb:person_koerperschaft/easydb:personen_koerperschaften"/>
        <xsl:message>Personen-ID - <xsl:value-of select="$pk_node/easydb:_system_object_id"/></xsl:message>
        <xsl:value-of select="$pk_node/easydb:_system_object_id[1]"/>
    </xsl:template>
 
    <!-- Rollen in Events -->
    <xsl:template name="rolle">
        <xsl:param name="person_node"/>
        <xsl:message>Rolle - <xsl:value-of select="$person_node/easydb:rolle/easydb:rollen/easydb:name/easydb:de-DE"/></xsl:message>
        <xsl:value-of select="$person_node/easydb:rolle/easydb:rollen/easydb:name/easydb:de-DE"/>
    </xsl:template>
 
    <!-- Rollen-ID in Events -->
    <xsl:template name="rollen-id">
        <xsl:param name="person_node"/>
        <xsl:message>Rollen-ID - <xsl:value-of select="$person_node/easydb:rolle/easydb:rollen/easydb:_system_object_id"/></xsl:message>
        <xsl:value-of select="$person_node/easydb:rolle/easydb:rollen/easydb:_system_object_id[1]"/>
    </xsl:template>
 
    <!-- Personen unsicher -->
    <xsl:template name="person-unsicher">
        <xsl:param name="person_node"/>
        <xsl:message>Person unsicher - <xsl:value-of select="$person_node/easydb:unsicher"/></xsl:message>
        <xsl:value-of select="$person_node/easydb:unsicher"/>
    </xsl:template>

    <!-- Orte in Events -->
    <xsl:template name="ort">
        <xsl:param name="ort_node"/>
        <xsl:variable name="o_node" select="$ort_node/easydb:ort/easydb:orte"/>
        <xsl:message>Ort - <xsl:value-of select="$o_node/easydb:_standard/easydb:*"
            /></xsl:message>
        <xsl:message>Geonames <xsl:value-of select="$o_node/easydb:custom[@name = 'geonames_id']/easydb:string[@name = 'conceptURI']"/></xsl:message>
        <!-- <xsl:value-of select="$o_node/easydb:custom[@name = 'geonames_id']/easydb:string[@name = 'conceptURI']"/><xsl:value-of select="$trennung"/> -->
        <xsl:value-of select="$o_node/easydb:name"/>
    </xsl:template>

    <!-- Ort-ID in Events -->
    <xsl:template name="ort-id">
        <xsl:param name="ort_node"/>
        <xsl:variable name="o_node" select="$ort_node/easydb:ort/easydb:orte"/>
        <xsl:message>Ort-ID - <xsl:value-of select="$o_node/easydb:_system_object_id"/></xsl:message>
        <xsl:value-of select="$o_node/easydb:_system_object_id[1]"/>
    </xsl:template>
    
    <!-- Ort unsicher -->
    <xsl:template name="ort-unsicher">
        <xsl:param name="ort_node"/>
         <xsl:message>Ort unsicher - <xsl:value-of select="$ort_node/easydb:unsicher"
        /></xsl:message>
        <xsl:value-of select="$ort_node/easydb:unsicher"/>
    </xsl:template>

    <!-- Zeitpunkt eines Events -->
    <xsl:template name="zeit">
        <xsl:param name="zeit_node"/>
        <xsl:message>Zeit - <xsl:value-of
                select="concat($zeit_node/easydb:datum_frei, ' / ', $zeit_node/easydb:datum_normiert/easydb:from, '-...')"
            /></xsl:message>
        <xsl:value-of select="$zeit_node/easydb:datum_frei"/><xsl:value-of select="$trennung"/>
        <xsl:value-of select="$zeit_node/easydb:datum_normiert/easydb:from"/><xsl:value-of select="$trennung"/>
        <xsl:value-of select="$zeit_node/easydb:datum_normiert/easydb:to"/><xsl:value-of select="$trennung"/>
        <xsl:value-of select="$zeit_node/easydb:unsicher"/><xsl:value-of select="$trennung"/>
    </xsl:template>

    <!-- Template zur Verarbeitung eines Objektdatensatzes -->
    <xsl:template match="easydb:objekte">
        <xsl:message>
            <xsl:value-of
                select="concat('--- Objekt ', easydb:_id, ' - ', easydb:_system_object_id[1])"/>
        </xsl:message>
        <xsl:value-of select="./easydb:_system_object_id[1]"/><xsl:text>;"</xsl:text>
        <xsl:value-of select="easydb:objekttitel/easydb:de-DE"/><xsl:value-of select="$trennung"/>
            <xsl:for-each
                select=".//easydb:ubmz_event_id[generate-id() = generate-id(key('events', concat(generate-id(ancestor::easydb:objekte), '.', .))[1])]">
                <xsl:sort
                    select="concat(9-index-of(reverse($eventreihenfolge),.),'.',ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]/easydb:datum_normiert/easydb:*[1])"
                    data-type="text"/>
                <xsl:message><xsl:value-of select="position()"/> Sortiere: <xsl:value-of
                    select="concat(9-index-of(reverse($eventreihenfolge),.),'.',ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]/easydb:datum_normiert/easydb:*[1])"
                    /></xsl:message>
                <xsl:message>Event <xsl:value-of select="."/> - <xsl:value-of select="name(ancestor::easydb:*[parent::easydb:objekte])"/></xsl:message>
                <xsl:value-of
                    select="./../../easydb:ereignisse/easydb:ubmz_event_id | ./../../easydb:rollen/easydb:ubmz_event_id"/>
                <xsl:value-of select="$trennung"/>
                <xsl:value-of
                    select="./../../easydb:ereignisse/easydb:name/easydb:de-DE | ./../../easydb:rollen/easydb:ubmz_name/easydb:de-DE"/>
                <xsl:value-of select="$trennung"/>
                <xsl:call-template name="zeit">
                    <xsl:with-param name="zeit_node" select="ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()][1]"/>
                </xsl:call-template>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__orte/easydb:objekte__orte[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="ort-id">
                        <xsl:with-param name="ort_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/>
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__orte/easydb:objekte__orte[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="ort">
                        <xsl:with-param name="ort_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/>
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__orte/easydb:objekte__orte[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="ort-unsicher">
                        <xsl:with-param name="ort_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/>
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="personen-id">
                        <xsl:with-param name="person_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/> 
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="person">
                        <xsl:with-param name="person_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/> 
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="rollen-id">
                        <xsl:with-param name="person_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/>
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="rolle">
                        <xsl:with-param name="person_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/>
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:for-each
                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]">
                    <xsl:call-template name="person-unsicher">
                        <xsl:with-param name="person_node" select="."/>
                    </xsl:call-template>
                    <xsl:value-of select="$trennungimfeld"/>
                </xsl:for-each>
                <xsl:value-of select="$trennung"/>
                <xsl:variable name="bemerkung">
                    <xsl:for-each
                        select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]/easydb:bemerkung">
                                <xsl:value-of select="translate(.,'&quot;','#')"/><text>; </text>
                    </xsl:for-each>
                    <xsl:for-each
                        select="ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()][1]/easydb:datum_bemerkung">
                                <xsl:text>Zum Datum: </xsl:text>
                                <xsl:value-of select="translate(.,'&quot;','#')"/><text>; </text>
                    </xsl:for-each>
                    <xsl:for-each
                        select="ancestor::easydb:objekte/easydb:_nested__objekte__orte/easydb:objekte__orte[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]/easydb:bemerkung">
                                <xsl:text> Zum Ort: </xsl:text>
                                <xsl:value-of select="translate(.,'&quot;','#')"/><text>; </text>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:value-of select="substring($bemerkung,1,string-length($bemerkung)-2)"/>
                <xsl:value-of select="$trennung"/>
                </xsl:for-each>
          <xsl:text>"&#13;</xsl:text>
    </xsl:template>

</xsl:stylesheet>
