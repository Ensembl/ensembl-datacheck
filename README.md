# Ensembl_thesis

<h2>Contains the new healthchecks in Perl for the Ensembl database.</h2>

Healthchecks are grouped in 5 categories:
<ol>
<li><b>'Hard' integrity:</b> entity and referential integrity.</li>
<li><b>'Soft' integrity:</b> user-defined integrity.</li>
<li><b>Schema-related sanity:</b> unique rows, blank & NULL values etc.</li>
<li><b>Data-related sanity:</b> Data format & values.</li>
<li><b>Comparison of databases and/or database versions</b></li>
</ol>

A set of 'old' healthchecks will be adapted into Perl using the Ensembl API.
For of the above categories a number of old healthchecks has been chosen to
demonstrate the concept. Further development and optimisation will follow.

Inital set of tests to be developed:
(by their old name, all can be found in: 
 https://github.com/Ensembl/ensj-healthcheck/tree/release/83/src/org/ensembl/healthcheck/testcase/generic )
 
<b> Category 1</b>
<ul>
<li>CoreForeignKeys</li>
<li>AncestralSequencesExtraChecks - (will probalby be merged into CoreForeignKeys)</li>
</ul>

<b> Category 2</b>
<ul>
<li>AssemblyMapping</li>
<li>AssemblyMultipleOverlap</li>
<li>FeatureCoors</li>
<li>LRG</li>
<li>Meta (& MetaCoords & MetaCrossSpecies & Metavalues (?))</li>
<li>ProjectXrefs</li>
<li>SeqRegionCoordSystem</li>
<li>VariationDensity</li>
<li>XrefTypes</li>
</ul>

<b> Category 3</b>
<ul>
<li>AutoIncrement</li>
<li>BlanksInsteadOfNulls</li>
<li>SchemaType</li>
<li>StableID</li>
</ul>

<b> Category 4</b>
<ul>
<li>AssemblyNameLength</li>
<li>DataFiles</li>
<li>GeneCount</li>
<li>NonGTACNSequency</li>
<li>XrefPrefixes</li>
</ul>

<b> Category 5</b>
<ul>
<li>ComparePreviousDatabases</li>
<li>CoordSystemAcrossSpecies</li>
<li>MySQLStorageEngine</li>
<li>ProductionMeta (or another Production test)</li>
<li>SeqRegionAcrossSpecies & SeqRegionAttribAcrossSpecies</li>
</ul>
