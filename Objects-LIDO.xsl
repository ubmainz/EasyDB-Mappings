<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:lido="http://www.lido-schema.org"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:easydb="https://schema.easydb.de/EASYDB/1.0/objects/" exclude-result-prefixes="xs"
    version="1.0">
    <xsl:output method="xml" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>

    <xsl:param name="version" select="2.6"/>
    <!-- Version dieser XSLT-Transformation -->
    <xsl:param name="language" select="'all'"/>
    <!-- bevorzugte Sprache z.B. en-US/de-DE/all -->
    <xsl:param name="authoritydata" select="'links'"/>
    <!-- all/links -->
    <xsl:param name="productionid" select="'ubmz-14'"/>
    <!-- ubmz-14 -->
    <xsl:param name="uri" select="'http://terminology.lido-schema.org/lido00099'"/>
    <!-- URI-Typ http://terminology.lido-schema.org/lido00099 oder auch URI -->
    <xsl:param name="local" select="'http://terminology.lido-schema.org/lido00100'"/>
    <!-- Local-Typ http://terminology.lido-schema.org/lido00100 oder auch local -->

    <!-- Der Schlüssel wird zum Deduplizieren der Events innerhalb eines Objekts gebraucht (Muenchscher Algorithmus) -->
    <xsl:key name="events" match="easydb:ubmz_event_id"
        use="concat(generate-id(ancestor::easydb:objekte), '.', .)"/>

    <!-- Hier geht's los -->
    <xsl:template match="/">
        <xsl:message>
            <xsl:value-of select="concat('Version ', $version)"/>
        </xsl:message>
        <xsl:message>LIDO Mapping...</xsl:message>
        <xsl:element name="lido:lidoWrap">
            <xsl:apply-templates/>
        </xsl:element>
        <xsl:message>LIDO Mapping fertig</xsl:message>
    </xsl:template>

    <!--  Universelles Datumshandling -->
    <xsl:template name="isodatetime">
        <xsl:param name="isofrom"/>
        <xsl:param name="isoto"/>
        <xsl:param name="displayfromto"/>
        <xsl:variable name="from" select="substring-before(concat($isofrom, 'T'), 'T')"/>
        <xsl:variable name="to" select="substring-before(concat($isoto, 'T'), 'T')"/>
        <xsl:message>
            <xsl:value-of select="concat('Date ', $isofrom, ' - ', $isoto, ' / ', $displayfromto)"/>
        </xsl:message>
        <xsl:element name="lido:displayDate">
            <xsl:choose>
                <xsl:when test="$displayfromto != ''">
                    <xsl:value-of select="$displayfromto"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$from"/>
                    <xsl:if test="$to != ''">
                        <xsl:value-of select="concat(' - ', $to)"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
        <xsl:element name="lido:date">
            <xsl:element name="lido:earliestDate">
                <xsl:value-of select="$from"/>
            </xsl:element>
            <xsl:element name="lido:latestDate">
                <xsl:choose>
                    <xsl:when test="$to != ''">
                        <xsl:value-of select="$to"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$from"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- Umsetzung der bevorzugten Sprache -->
    <xsl:template name="languagetext">
        <xsl:param name="textnode"/>
        <xsl:param name="elementname"/>
        <xsl:choose>
            <xsl:when
                test="($language != 'all') and $textnode/easydb:*[contains(name(), $language)]/text()">
                <xsl:element name="{$elementname}">
                    <xsl:attribute name="xml:lang">
                        <xsl:value-of select="substring-before($language, '-')"/>
                    </xsl:attribute>
                    <xsl:value-of select="$textnode/easydb:*[name() = $language]"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$textnode/easydb:*">
                    <xsl:element name="{$elementname}">
                        <xsl:attribute name="xml:lang">
                            <xsl:choose>
                                <xsl:when test="contains(name(.), ':')">
                                    <xsl:value-of
                                        select="substring-before(substring-after(name(.), ':'), '-')"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="substring-before(name(.), '-')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="defaultlanguage">
        <xsl:choose>
            <xsl:when test="$language != 'all'">
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="substring-before($language, '-')"/>
                </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="xml:lang">
                    <xsl:value-of select="'de'"/>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Personen in Events -->
    <xsl:template name="person">
        <xsl:param name="person_node"/>
        <xsl:variable name="pk_node"
            select="$person_node/easydb:person_koerperschaft/easydb:personen_koerperschaften"/>
        <xsl:message>Person - <xsl:value-of select="($pk_node/easydb:_standard/easydb:*)[1]"
            /></xsl:message>
        <xsl:if test="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']">
            <xsl:message>GND <xsl:value-of
                    select="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']"
                /></xsl:message>
        </xsl:if>
        <xsl:element name="lido:eventActor">
            <xsl:element name="lido:displayActorInRole">
                <xsl:value-of select="$pk_node/easydb:name"/>
            </xsl:element>
            <xsl:element name="lido:actorInRole">
                <xsl:choose>
                    <xsl:when
                        test="($authoritydata = 'all') and $pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']">
                        <xsl:element name="lido:actor">
                            <xsl:element name="lido:actorID">
                                <xsl:attribute name="lido:type">
                                    <xsl:value-of select="$uri"/>
                                </xsl:attribute>
                                <xsl:attribute name="lido:source"
                                    >http://d-nb.info/gnd</xsl:attribute>
                                <xsl:value-of
                                    select="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']"
                                />
                            </xsl:element>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="lido:actor">
                            <xsl:if
                                test="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']">
                                <xsl:element name="lido:actorID">
                                    <xsl:attribute name="lido:type">
                                        <xsl:value-of select="$uri"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="lido:source"
                                        >http://d-nb.info/gnd</xsl:attribute>
                                    <xsl:value-of
                                        select="$pk_node/easydb:custom[@name = 'gnd_id']/easydb:string[@name = 'conceptURI']"
                                    />
                                </xsl:element>
                            </xsl:if>
                            <xsl:element name="lido:nameActorSet">
                                <xsl:element name="lido:appellationValue">
                                    <xsl:attribute name="lido:pref">http://terminology.lido-schema.org/lido00169</xsl:attribute>
                                    <xsl:value-of select="$pk_node/easydb:name"/>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:element name="lido:roleActor">
                    <xsl:element name="lido:conceptID">
                        <xsl:attribute name="lido:type">
                            <xsl:value-of select="$uri"/>
                        </xsl:attribute>
                        <xsl:attribute name="lido:source"
                            >http://id.loc.gov/vocabulary/relators/</xsl:attribute>
                        <xsl:value-of
                            select="concat('http://id.loc.gov/vocabulary/relators/', $person_node/easydb:rolle/easydb:rollen/easydb:marcrelator)"
                        />
                    </xsl:element>
                    <xsl:call-template name="languagetext">
                        <xsl:with-param name="textnode"
                            select="$person_node/easydb:rolle/easydb:rollen/easydb:marcrelator_name"/>
                        <xsl:with-param name="elementname" select="'lido:term'"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!--  Template zur Verarbeitung von Ortshierarchien -->
    <xsl:template name="parentplace">
        <xsl:param name="pathnode"/>
        <xsl:param name="level"/>
        <xsl:if test="$pathnode/easydb:orte[@level = $level]">
            <xsl:message>Ortspfad <xsl:value-of
                    select="$pathnode/easydb:orte[@parent-level = $level]/easydb:_standard/easydb:de-DE"
                /> Level <xsl:value-of select="$level"/></xsl:message>
            <xsl:element name="lido:partOfPlace">
                <xsl:element name="lido:namePlaceSet">
                    <xsl:element name="lido:appellationValue">
                        <!-- Workaround für die Ortswiederholungen -->
                        <xsl:value-of
                            select="substring-before(concat($pathnode/easydb:orte[@parent-level = $level]/easydb:_standard/easydb:de-DE,','),',')"
                        />
                    </xsl:element>
                </xsl:element>
                <xsl:call-template name="parentplace">
                    <xsl:with-param name="pathnode" select="$pathnode"/>
                    <xsl:with-param name="level" select="$level + 1"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- Orte in Events -->
    <xsl:template name="ort">
        <xsl:param name="ort_node"/>
        <xsl:variable name="o_node" select="$ort_node/easydb:ort/easydb:orte"/>
        <xsl:message>Ort - <xsl:value-of select="($o_node/easydb:_standard/easydb:*)[1]"
            /></xsl:message>
        <xsl:element name="lido:eventPlace">
            <xsl:element name="lido:place">
                <xsl:if
                    test="$o_node/easydb:custom[@name = 'geonames_id']/easydb:string[@name = 'conceptURI']">
                    <xsl:message>Geonames <xsl:value-of
                            select="$o_node/easydb:custom[@name = 'geonames_id']/easydb:string[@name = 'conceptURI']"
                        /></xsl:message>
                    <xsl:element name="lido:placeID">
                        <xsl:attribute name="lido:type">
                            <xsl:value-of select="$uri"/>
                        </xsl:attribute>
                        <xsl:attribute name="lido:source">http://sws.geonames.org</xsl:attribute>
                        <xsl:value-of
                            select="$o_node/easydb:custom[@name = 'geonames_id']/easydb:string[@name = 'conceptURI']"
                        />
                    </xsl:element>
                </xsl:if>
                <xsl:element name="lido:namePlaceSet">
                    <xsl:element name="lido:appellationValue">
                        <xsl:attribute name="lido:pref">http://terminology.lido-schema.org/lido00169</xsl:attribute>
                        <xsl:value-of select="$o_node/easydb:name"/>
                    </xsl:element>
                </xsl:element>
                <xsl:call-template name="parentplace">
                    <xsl:with-param name="pathnode" select="$o_node/easydb:_path"/>
                    <xsl:with-param name="level" select="1"/>
                </xsl:call-template>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- Zeitpunkt eines Events -->
    <xsl:template name="zeit">
        <xsl:param name="zeit_node"/>
        <xsl:message>Zeit - <xsl:value-of
                select="concat($zeit_node/easydb:datum_frei, ' / ', $zeit_node/easydb:datum_normiert/easydb:from, '-...')"
            /></xsl:message>
        <xsl:element name="lido:eventDate">
            <xsl:call-template name="isodatetime">
                <xsl:with-param name="isofrom" select="$zeit_node/easydb:datum_normiert/easydb:from"/>
                <xsl:with-param name="isoto" select="$zeit_node/easydb:datum_normiert/easydb:to"/>
                <xsl:with-param name="displayfromto" select="$zeit_node/easydb:datum_frei"/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>

    <!-- Template zur Verarbeitung eines Objektdatensatzes -->
    <xsl:template match="easydb:objekte">
        <xsl:message>
            <xsl:value-of
                select="concat('--- Objekt ', easydb:_id, ' - ', easydb:_system_object_id)"/>
        </xsl:message>
        <xsl:element name="lido:lido">
            <xsl:element name="lido:lidoRecID">
                <xsl:attribute name="lido:type">
                    <xsl:value-of select="$local"/>
                </xsl:attribute>
                <xsl:value-of select="concat('DE-MUS-094228-',./easydb:_system_object_id)"/>
            </xsl:element>

            <xsl:element name="lido:descriptiveMetadata">
                <xsl:call-template name="defaultlanguage"/>
                <xsl:element name="lido:objectClassificationWrap">
                    <xsl:element name="lido:objectWorkTypeWrap">
                        <xsl:element name="lido:objectWorkType">
                            <xsl:if test="easydb:custom[(@name = 'objektbezeichnung_aat') and (@type = 'custom:base.custom-data-type-getty.getty')]">
                                <xsl:element name="skos:Concept">
                                    <xsl:attribute name="rdf:about"><xsl:value-of
                                        select="easydb:custom[(@name = 'objektbezeichnung_aat')]/easydb:string[@name = 'conceptURI']"/></xsl:attribute>
                                    <xsl:element name="skos:prefLabel"><xsl:attribute name="xml:lang">en</xsl:attribute><xsl:value-of
                                        select="easydb:custom[(@name = 'objektbezeichnung_aat')]/easydb:string[@name = 'conceptName']"/></xsl:element>
                                </xsl:element>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when
                                    test="easydb:custom[(@name = 'objektbezeichnung') and (@type = 'custom:base.custom-data-type-gnd.gnd')]/easydb:string[@name = 'conceptName']/text()">
                                    <xsl:element name="lido:conceptID">
                                        <xsl:attribute name="lido:type">
                                            <xsl:value-of select="$uri"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="lido:source"
                                            >https://d-nb.info/gnd</xsl:attribute>
                                        <xsl:value-of
                                            select="easydb:custom[(@name = 'objektbezeichnung') and (@type = 'custom:base.custom-data-type-gnd.gnd')]/easydb:string[@name = 'conceptURI']"
                                        />
                                    </xsl:element>
                                    <xsl:element name="lido:term">
                                        <xsl:attribute name="lido:pref">http://terminology.lido-schema.org/lido00526</xsl:attribute>
                                        <xsl:attribute name="xml:lang">de</xsl:attribute>
                                        <xsl:value-of
                                            select="easydb:custom[(@name = 'objektbezeichnung') and (@type = 'custom:base.custom-data-type-gnd.gnd')]/easydb:string[@name = 'conceptName']"
                                        />
                                    </xsl:element>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:element name="lido:term">
                                        <xsl:attribute name="xml:lang">
                                            <xsl:value-of select="'de'"/>
                                        </xsl:attribute>
                                        <xsl:text>Objekt</xsl:text>
                                    </xsl:element>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:classificationWrap">
                        <xsl:element name="lido:classification">
                            <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00853</xsl:attribute>
                            <xsl:element name="lido:conceptID">
                                <xsl:attribute name="lido:type">
                                    <xsl:value-of select="$uri"/>
                                </xsl:attribute>
                                <xsl:attribute name="lido:source"
                                    >https://portal.wissenschaftliche-sammlungen.de/ConceptScheme/33</xsl:attribute>
                                <xsl:value-of
                                    select="easydb:objektkategorie/easydb:objektkategorien/easydb:uri"
                                />
                            </xsl:element>
                            <xsl:call-template name="languagetext">
                                <xsl:with-param name="textnode"
                                    select="easydb:objektkategorie/easydb:objektkategorien/easydb:name"/>
                                <xsl:with-param name="elementname" select="'lido:term'"/>
                            </xsl:call-template>
                        </xsl:element>
                        <xsl:for-each
                            select="easydb:_nested__objekte__systematiken_geowissenschaften/easydb:objekte__systematiken_geowissenschaften/easydb:systematik_geowissenschaften/easydb:systematik_geowissenschaften">
                            <xsl:element name="lido:classification">
                                <xsl:attribute name="lido:type">Klassifikation</xsl:attribute> <!-- DDB -->
                                <xsl:call-template name="languagetext">
                                    <xsl:with-param name="textnode"
                                        select="easydb:_standard | easydb:_standardtechnik"/>
                                    <xsl:with-param name="elementname" select="'lido:term'"/>
                                </xsl:call-template>
                            </xsl:element>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="lido:objectIdentificationWrap">
                    <xsl:element name="lido:titleWrap">
                        <xsl:element name="lido:titleSet">
                            <xsl:attribute name="lido:pref">preferred</xsl:attribute>
                            <xsl:call-template name="languagetext">
                                <xsl:with-param name="textnode" select="easydb:objekttitel"/>
                                <xsl:with-param name="elementname" select="'lido:appellationValue'"
                                />
                            </xsl:call-template>
                        </xsl:element>
                        <xsl:if test="easydb:urspruenglicher_name">
                            <xsl:element name="lido:titleSet">
                                <xsl:attribute name="lido:type">http://vocab.getty.edu/aat/300417204</xsl:attribute>
                                <xsl:element name="lido:appellationValue">
                                    <xsl:attribute name="xml:lang"><xsl:value-of select="easydb:sprache/easydb:sprachen/easydb:iso"/></xsl:attribute>
                                    <xsl:value-of select="easydb:urspruenglicher_name"/>
                                </xsl:element>
                            </xsl:element>
                        </xsl:if>
                    </xsl:element>
                    <xsl:element name="lido:inscriptionsWrap">
                        <xsl:for-each select="easydb:_nested__objekte__beschriftungen/easydb:objekte__beschriftungen">
                                <xsl:element name="lido:inscriptions">
                                    <xsl:choose>
                                        <xsl:when test="easydb:beschriftungstyp/easydb:typ_beschriftung/easydb:name/easydb:de-DE='Inschrift'"><xsl:attribute name="type">http://vocab.getty.edu/aat/300028702</xsl:attribute></xsl:when>
                                    </xsl:choose>
                                    <xsl:element name="lido:inscriptionDescription">
                                            <xsl:element name="lido:descriptiveNoteValue">
                                                <xsl:value-of select="easydb:beschriftung"/>
                                            </xsl:element>
                                        </xsl:element>
                                    </xsl:element>   
                            </xsl:for-each>
                     </xsl:element>
                    <xsl:element name="lido:repositoryWrap">
                        <xsl:element name="lido:repositorySet">
                            <xsl:attribute name="lido:type"
                                >http://terminology.lido-schema.org/lido00475</xsl:attribute>
                            <xsl:element name="lido:repositoryName">
                                <xsl:element name="lido:legalBodyID">
                                    <xsl:attribute name="lido:type"><xsl:value-of select="$uri"
                                        /></xsl:attribute>
                                    <xsl:attribute name="lido:source"
                                        >https://sigel.staatsbibliothek-berlin.de</xsl:attribute>https://ld.zdb-services.de/resource/organisations/DE-MUS-094228</xsl:element>
                                <xsl:element name="lido:legalBodyName">
                                    <xsl:element name="lido:appellationValue">
                                         <xsl:value-of select="'Sammlungen der Johannes Gutenberg-Universität Mainz'"/>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:element>
                            <xsl:element name="lido:workID">
                                <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00113</xsl:attribute> <!-- Inventarnummer (DDB) -->
                                <xsl:value-of select="easydb:inventarnummer"/>
                            </xsl:element>
                            <xsl:for-each select="easydb:_nested__objekte__weitere_nummern/easydb:objekte__weitere_nummern">
                                <xsl:element name="lido:workID">
                                    <xsl:choose>
                                        <xsl:when test="easydb:typ/easydb:typ_weitere_nummern/easydb:name='alte Inventarnummer'">
                                            <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00188</xsl:attribute> <!-- alte Inventarnummer (DDB) -->
                                        </xsl:when>
                                    </xsl:choose>
                                    <xsl:value-of select="easydb:nummer"/>
                                </xsl:element>
                            </xsl:for-each>
                            <xsl:element name="lido:repositoryLocation">
                                <xsl:element name="lido:placeID">
                                    <xsl:attribute name="lido:type">
                                        <xsl:value-of select="$uri"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="lido:source"
                                        >http://sws.geonames.org</xsl:attribute>
                                    <xsl:text>http://www.geonames.org/6554818></xsl:text>
                                </xsl:element>
                                <xsl:element name="lido:namePlaceSet">
                                    <xsl:element name="lido:appellationValue">
                                        <xsl:attribute name="lido:pref">http://terminology.lido-schema.org/lido00169</xsl:attribute>
                                        <xsl:text>Mainz</xsl:text>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:objectDescriptionWrap">
                        <xsl:element name="lido:objectDescriptionSet">
                            <xsl:element name="lido:descriptiveNoteValue">
                                <xsl:value-of select="easydb:objektbeschreibung"/>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:objectMeasurementsWrap">
                        <xsl:if test="easydb:masse/text()">
                            <xsl:element name="lido:objectMeasurementsSet">
                                <xsl:element name="lido:displayObjectMeasurements">
                                    <xsl:value-of select="easydb:masse"/>
                                </xsl:element>
                            </xsl:element>
                        </xsl:if>
                        <xsl:if test="easydb:groesse/text()">
                            <xsl:element name="lido:objectMeasurementsSet">
                                <xsl:element name="lido:objectMeasurements">
                                    <xsl:element name="lido:measurementsSet">
                                        <xsl:choose>
                                            <xsl:when test="$language = 'de-DE'">
                                                <xsl:element name="lido:measurementType">
                                                  <xsl:attribute name="xml:lang">de</xsl:attribute>
                                                  <xsl:text>Größe</xsl:text>
                                                </xsl:element>
                                            </xsl:when>
                                            <xsl:when test="$language = 'en-US'">
                                                <xsl:element name="lido:measurementType">
                                                  <xsl:attribute name="xml:lang">en</xsl:attribute>
                                                  <xsl:text>Size</xsl:text>
                                                </xsl:element>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:element name="lido:measurementType">
                                                  <xsl:attribute name="xml:lang">de</xsl:attribute>
                                                  <xsl:text>Größe</xsl:text>
                                                </xsl:element>
                                                <xsl:element name="lido:measurementType">
                                                  <xsl:attribute name="xml:lang">en</xsl:attribute>
                                                  <xsl:text>Size</xsl:text>
                                                </xsl:element>
                                            </xsl:otherwise>
                                          </xsl:choose>
                                      <xsl:element name="lido:measurementUnit">
                                            <xsl:value-of
                                                select="easydb:groesse_einheit/easydb:einheiten_groesse/easydb:name"
                                            />
                                        </xsl:element>
                                        <xsl:element name="lido:measurementValue">
                                            <xsl:value-of select="easydb:groesse"/>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:element>
                            </xsl:element>
                        </xsl:if>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="lido:eventWrap">
                    <xsl:for-each
                        select=".//easydb:ubmz_event_id[generate-id() = generate-id(key('events', concat(generate-id(ancestor::easydb:objekte), '.', .))[1])]">
                        <xsl:sort
                            select="concat(number(.!=$productionid),'.',ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]/easydb:datum_normiert/easydb:*[1])"
                            data-type="text"/>
                        <xsl:message><xsl:value-of select="position()"/> Sortiere: <xsl:value-of
                            select="concat(number(.!=$productionid),'.',ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]/easydb:datum_normiert/easydb:*[1])"
                            /></xsl:message>
                        <xsl:message>Event <xsl:value-of select="."/> - <xsl:value-of
                                select="name(ancestor::easydb:*[parent::easydb:objekte])"
                            /></xsl:message>
                        <xsl:element name="lido:eventSet">
                            <xsl:attribute name="lido:sortorder">
                                <xsl:number value="position()"/>
                            </xsl:attribute>
                            <xsl:call-template name="languagetext">
                                <xsl:with-param name="textnode"
                                    select="./../../easydb:ereignisse/easydb:name | ./../../easydb:rollen/easydb:ubmz_name"/>
                                <xsl:with-param name="elementname" select="'lido:displayEvent'"/>
                            </xsl:call-template>
                            <xsl:element name="lido:event">
                                <xsl:element name="lido:eventType">
                                    <xsl:element name="lido:conceptID">
                                        <xsl:attribute name="lido:type">
                                            <xsl:value-of select="$uri"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="lido:source"
                                            >http://terminology.lido-schema.org/eventType</xsl:attribute>
                                        <xsl:text>http://terminology.lido-schema.org/</xsl:text>
                                        <xsl:value-of
                                            select="../easydb:lido_id | ../easydb:lido_event"/>
                                    </xsl:element>

                                    <xsl:call-template name="languagetext">
                                        <xsl:with-param name="textnode"
                                            select="./../easydb:lido_name"/>
                                        <xsl:with-param name="elementname" select="'lido:term'"/>
                                    </xsl:call-template>

                                </xsl:element>
                                <xsl:for-each
                                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]">
                                    <xsl:call-template name="person">
                                        <xsl:with-param name="person_node" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                                <xsl:if test="current() = $productionid">
                                    <xsl:apply-templates
                                        select="ancestor::easydb:objekte/easydb:_nested__objekte__kulturbezug/easydb:objekte__kulturbezug/easydb:kulturbezug/easydb:kulturbezug"
                                    />
                                </xsl:if>
                                <xsl:for-each
                                    select="ancestor::easydb:objekte/easydb:_nested__objekte__datumsangaben/easydb:objekte__datumsangaben[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]">
                                    <xsl:call-template name="zeit">
                                        <xsl:with-param name="zeit_node" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                                <xsl:for-each
                                    select="ancestor::easydb:objekte/easydb:_nested__objekte__orte/easydb:objekte__orte[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]">
                                    <xsl:call-template name="ort">
                                        <xsl:with-param name="ort_node" select="."/>
                                    </xsl:call-template>
                                </xsl:for-each>
                                <!-- Material+Technik+Kulturbezug kommt nur, wenn es das Event Produktion schon über Zeit/Personen/Ort gibt -->
                                <xsl:if test="current() = $productionid">
                                    <xsl:apply-templates
                                        select="ancestor::easydb:objekte/easydb:_nested__objekte__materialien/easydb:objekte__materialien/easydb:material/easydb:material | ancestor::easydb:objekte/easydb:_nested__objekte__techniken/easydb:objekte__techniken/easydb:technik/easydb:technik"
                                    />
                                </xsl:if>
                                <xsl:for-each
                                    select="ancestor::easydb:objekte/easydb:_nested__objekte__personen_koerperschaften/easydb:objekte__personen_koerperschaften[easydb:rolle/easydb:rollen/easydb:ubmz_event_id = current()]/easydb:bemerkung">
                                    <xsl:element name="lido:eventDescriptionSet">
                                        <xsl:element name="lido:descriptiveNoteValue">
                                            <xsl:value-of select="."/>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:for-each>
                                <xsl:for-each
                                    select="ancestor::easydb:objekte/easydb:_nested__objekte__orte/easydb:objekte__orte[easydb:ereignis/easydb:ereignisse/easydb:ubmz_event_id = current()]/easydb:ort/easydb:orte/easydb:bemerkung">
                                    <xsl:element name="lido:eventDescriptionSet">
                                        <xsl:element name="lido:descriptiveNoteValue">
                                            <xsl:text>Ergänzung zum Ort: </xsl:text><xsl:value-of select="."/>
                                        </xsl:element>
                                    </xsl:element>
                                </xsl:for-each>
                             </xsl:element>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:element>
                <xsl:element name="lido:objectRelationWrap">
                    <xsl:element name="lido:subjectWrap">
                        <xsl:for-each select=".//easydb:verwendung/easydb:verwendung">
                            <xsl:element name="lido:subjectSet">
                                <xsl:element name="lido:displaySubject">
                                    <xsl:value-of select="easydb:name"/>
                                </xsl:element>
                            </xsl:element>
                        </xsl:for-each>
                    </xsl:element>
                </xsl:element>
            </xsl:element>

            <xsl:element name="lido:administrativeMetadata">
                <xsl:call-template name="defaultlanguage"/>
                <xsl:element name="lido:recordWrap">
                    <xsl:element name="lido:recordID">
                        <xsl:attribute name="lido:type">
                            <xsl:value-of select="$local"/>
                        </xsl:attribute>
                        <xsl:value-of select="easydb:_system_object_id"/>
                    </xsl:element>
                    <xsl:element name="lido:recordType">
                        <xsl:element name="skos:Concept">
                            <xsl:attribute name="rdf:about">http://terminology.lido-schema.org/lido00141</xsl:attribute>
                            <xsl:element name="skos:prefLabel">
                                <xsl:attribute name="xml:lang">en</xsl:attribute>
                                <xsl:text>Item-level record</xsl:text></xsl:element>
                        </xsl:element>
                        <xsl:element name="lido:conceptID"><xsl:attribute name="lido:type"
                                    ><xsl:value-of select="$uri"
                            /></xsl:attribute>http://terminology.lido-schema.org/lido00141</xsl:element>
                        <xsl:element name="lido:term"><xsl:attribute name="xml:lang"
                                >de</xsl:attribute>Einzelobjekt</xsl:element>
                        <xsl:element name="lido:term"><xsl:attribute name="xml:lang"
                                >en</xsl:attribute>item</xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:recordSource">
                        <xsl:element name="lido:legalBodyID">
                            <xsl:attribute name="lido:type"><xsl:value-of select="$uri"
                                /></xsl:attribute>
                            <xsl:attribute name="lido:source"
                                >https://sigel.staatsbibliothek-berlin.de</xsl:attribute>https://ld.zdb-services.de/resource/organisations/DE-MUS-094228</xsl:element>
                        <xsl:element name="lido:legalBodyName">
                            <xsl:element name="lido:appellationValue">
                                <xsl:attribute name="xml:lang">en</xsl:attribute>
                                <xsl:text>Collections of the Johannes Gutenberg University Mainz</xsl:text>
                            </xsl:element>
                            <xsl:element name="lido:appellationValue">
                                <xsl:attribute name="xml:lang">de</xsl:attribute>
                                <xsl:text>Sammlungen der Johannes Gutenberg-Universität Mainz</xsl:text>
                            </xsl:element>
                        </xsl:element>
                        <xsl:element name="lido:legalBodyWeblink"
                            >https://www.ub.uni-mainz.de/de/universitaetssammlungen</xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:recordRights">
                        <xsl:element name="lido:rightsType">
                            <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00921</xsl:attribute>
                            <xsl:element name="skos:Concept">
                                <xsl:attribute name="rdf:about">http://creativecommons.org/publicdomain/zero/1.0/</xsl:attribute>
                                <xsl:element name="skos:prefLabel">
                                    <xsl:text>CC0 1.0</xsl:text></xsl:element>
                            </xsl:element>
                            <xsl:element name="lido:conceptID">
                                <xsl:attribute name="lido:type"
                                    >http://terminology.lido-schema.org/lido00099</xsl:attribute>
                                <xsl:attribute name="lido:source"
                                    >http://creativecommons.org</xsl:attribute>
                                <xsl:text>http://creativecommons.org/publicdomain/zero/1.0/</xsl:text>
                            </xsl:element>
                            <xsl:element name="lido:term">CC0 1.0</xsl:element>
                        </xsl:element>
                    </xsl:element>
 <!-- noch nicht online
                    <xsl:element name="lido:recordInfoSet">
                        <xsl:attribute name="lido:type"
                            >http://terminology.lido-schema.org/lido00471</xsl:attribute>
                        <xsl:element name="lido:recordInfoLink">
                            <xsl:value-of select="easydb:_urls/easydb:url[@type = 'easydb-id']"/>
                        </xsl:element>
                    </xsl:element>
-->
                    <xsl:element name="lido:collection">
                        <xsl:element name="lido:object">
                            <xsl:element name="lido:objectType">
                                <xsl:element name="skos:Concept">
                                    <xsl:attribute name="rdf:about">http://terminology.lido-schema.org/lido01034</xsl:attribute>
                                    <xsl:element name="skos:prefLabel">
                                        <xsl:attribute name="xml:lang">en</xsl:attribute>
                                        <xsl:text>Physical collection</xsl:text></xsl:element>
                                </xsl:element>
                            </xsl:element>
                            <xsl:element name="lido:objectName">
                                <xsl:element name="lido:appellationValue"><xsl:value-of select="normalize-space(easydb:pool)"/></xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:collection">
                        <xsl:element name="lido:object">
                            <xsl:element name="lido:objectWebResource">https://ccc.deutsche-digitale-bibliothek.de/</xsl:element>
                            <xsl:element name="lido:objectType">
                                <xsl:element name="skos:Concept">
                                    <xsl:attribute name="rdf:about">http://terminology.lido-schema.org/lido01055</xsl:attribute>
                                    <xsl:element name="skos:prefLabel">
                                        <xsl:attribute name="xml:lang">en</xsl:attribute>
                                        <xsl:text>Online collection</xsl:text></xsl:element>
                                </xsl:element>
                            </xsl:element>
                            <xsl:element name="lido:objectName">
                                <xsl:element name="lido:appellationValue">Collections from Colonial Contexts</xsl:element>
                            </xsl:element>
                        </xsl:element>
                    </xsl:element>
                </xsl:element>
                <xsl:element name="lido:resourceWrap">
                    <xsl:apply-templates
                        select="easydb:_reverse_nested__bilder__objekt/easydb:bilder"/>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- Template zur Verarbeitung eines Digitalisatlinks -->
    <xsl:template match="easydb:bilder">
        <xsl:message>Bild <xsl:value-of
                select="easydb:datei/easydb:files/easydb:file/easydb:date_created"/></xsl:message>
        <xsl:element name="lido:resourceSet">
            <xsl:attribute name="lido:sortorder">
                <xsl:number value="position()"/>
            </xsl:attribute>
            <xsl:element name="lido:resourceID">
                <xsl:attribute name="lido:type">
                    <xsl:value-of select="$local"/>
                </xsl:attribute>
                <xsl:value-of select="easydb:datei/easydb:files/easydb:file/easydb:original_filename"/></xsl:element>
            <xsl:element name="lido:resourceRepresentation">
                <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00451</xsl:attribute>
                <xsl:element name="lido:linkResource">
                    <xsl:attribute name="lido:formatResource"><xsl:value-of select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'preview']/easydb:extension"/></xsl:attribute>
                    <xsl:value-of
                        select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'preview']/easydb:url"
                    />
                </xsl:element>
                <xsl:element name="lido:resourceMeasurementsSet">
                    <xsl:element name="lido:measurementType"><xsl:attribute name="xml:lang">en</xsl:attribute>width</xsl:element>
                    <xsl:element name="lido:measurementUnit"><xsl:attribute name="xml:lang">en</xsl:attribute>pixel</xsl:element>
                    <xsl:element name="lido:measurementValue"><xsl:value-of select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'preview']/easydb:width"/></xsl:element>
                </xsl:element>
                <xsl:element name="lido:resourceMeasurementsSet">
                    <xsl:element name="lido:measurementType"><xsl:attribute name="xml:lang">en</xsl:attribute>height</xsl:element>
                    <xsl:element name="lido:measurementUnit"><xsl:attribute name="xml:lang">en</xsl:attribute>pixel</xsl:element>
                    <xsl:element name="lido:measurementValue"><xsl:value-of select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'preview']/easydb:height"/></xsl:element>
                </xsl:element>
            </xsl:element>
            <xsl:element name="lido:resourceRepresentation">
                <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00464</xsl:attribute>
                <xsl:element name="lido:linkResource">
                    <xsl:value-of
                        select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'full']/easydb:url"
                    />
                </xsl:element>
                <xsl:element name="lido:resourceMeasurementsSet">
                    <xsl:element name="lido:measurementType"><xsl:attribute name="xml:lang">en</xsl:attribute>width</xsl:element>
                    <xsl:element name="lido:measurementUnit"><xsl:attribute name="xml:lang">en</xsl:attribute>pixel</xsl:element>
                    <xsl:element name="lido:measurementValue"><xsl:value-of select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'full']/easydb:width"/></xsl:element>
                </xsl:element>
                <xsl:element name="lido:resourceMeasurementsSet">
                    <xsl:element name="lido:measurementType"><xsl:attribute name="xml:lang">en</xsl:attribute>height</xsl:element>
                    <xsl:element name="lido:measurementUnit"><xsl:attribute name="xml:lang">en</xsl:attribute>pixel</xsl:element>
                    <xsl:element name="lido:measurementValue"><xsl:value-of select="easydb:datei/easydb:files/easydb:file/easydb:versions/easydb:version[@name = 'full']/easydb:height"/></xsl:element>
                </xsl:element>
            </xsl:element>
            <xsl:element name="lido:resourceType"> <!-- DDB -->
                <xsl:element name="lido:term">IMAGE</xsl:element>
            </xsl:element>
            <xsl:element name="lido:resourceDateTaken">
                <xsl:call-template name="isodatetime">
                    <xsl:with-param name="isofrom"
                        select="easydb:datei/easydb:files/easydb:file/easydb:date_created"/>
                </xsl:call-template>
            </xsl:element>
            <xsl:element name="lido:rightsResource">
                <xsl:element name="lido:rightsType">
                    <xsl:attribute name="lido:type">http://terminology.lido-schema.org/lido00921</xsl:attribute>
                    <xsl:element name="skos:Concept">
                        <xsl:attribute name="rdf:about"><xsl:value-of select="easydb:lizenz/easydb:lizenzen/easydb:link"/></xsl:attribute>
                        <xsl:element name="skos:prefLabel">
                            <xsl:value-of select="easydb:lizenz/easydb:lizenzen/easydb:name/easydb:en-US"/></xsl:element>
                    </xsl:element>
                    <xsl:element name="lido:conceptID">
                        <xsl:attribute name="lido:type"><xsl:value-of select="$uri"/></xsl:attribute>
                        <xsl:attribute name="lido:source">http://creativecommons.org</xsl:attribute>
                        <xsl:value-of select="easydb:lizenz/easydb:lizenzen/easydb:link"/>
                    </xsl:element>
                    <xsl:element name="lido:term"><xsl:value-of select="easydb:lizenz/easydb:lizenzen/easydb:name/easydb:en-US"/></xsl:element>
                </xsl:element>
                <xsl:element name="lido:creditLine">
                    <xsl:value-of select="easydb:urheber/easydb:urheber/easydb:name"/>
                </xsl:element>
            </xsl:element>    
        </xsl:element>
    </xsl:template>

    <!-- Templates für Material und Technik im Produktions-Event -->

    <xsl:template name="mut">
        <xsl:param name="lidoid"/>
        <xsl:element name="lido:eventMaterialsTech">
            <xsl:element name="lido:materialsTech">
                <xsl:element name="lido:termMaterialsTech">
                    <xsl:attribute name="lido:type">
                        <xsl:value-of select="$lidoid"/>
                    </xsl:attribute>
                    <xsl:if test="easydb:dnb">
                        <xsl:element name="lido:conceptID">
                            <xsl:attribute name="lido:type">
                                <xsl:value-of select="$uri"/>
                            </xsl:attribute>
                            <xsl:attribute name="lido:source">https://d-nb.info/gnd</xsl:attribute>
                            <xsl:value-of select="easydb:dnb"/>
                        </xsl:element>
                    </xsl:if>
                    <xsl:if test="easydb:getty">
                        <xsl:element name="lido:conceptID">
                            <xsl:attribute name="lido:type">
                                <xsl:value-of select="$uri"/>
                            </xsl:attribute>
                            <xsl:attribute name="lido:source"
                                >http://vocab.getty.edu/aat</xsl:attribute>
                            <xsl:value-of select="easydb:getty"/>
                        </xsl:element>
                    </xsl:if>
                    <xsl:call-template name="languagetext">
                        <xsl:with-param name="textnode" select="easydb:name"/>
                        <xsl:with-param name="elementname" select="'lido:term'"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>


    <xsl:template match="easydb:material">
        <xsl:message>Material </xsl:message>
        <xsl:call-template name="mut">
            <xsl:with-param name="lidoid"
                >http://terminology.lido-schema.org/lido00132</xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="easydb:technik">
        <xsl:message>Technik </xsl:message>
        <xsl:call-template name="mut">
            <xsl:with-param name="lidoid"
                >http://terminology.lido-schema.org/lido00131</xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="easydb:kulturbezug">
        <xsl:message>Kultur </xsl:message>
        <xsl:element name="lido:culture">
            <xsl:element name="lido:term">
                <xsl:value-of select="easydb:name"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
