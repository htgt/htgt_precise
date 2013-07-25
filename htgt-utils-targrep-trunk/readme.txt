Current Issues with script.

1. DistributionQc is created for all es_cells even if they have no data (i.e. all the values are nill)


What needs to be set up to sucessfully deploy script.

1. environment.conf (brave_new_world)
   Add new environment variables TARMITS_DB and TARMITS_CLIENT_CONF.
   Set TARMITS_DB = tarmits
   Set TARMITS_CLIENT_CONF to point to tarmit database config file for each environment

2. Add database config files to brave_new_world for each environment to point to the database corresponding to the environment

3. dbconnect.cfg (brave_new_world)

   Add database connections for tarmits (live staging/test, labs)

<Database tarmits_test>
    dsn = dbi:Pg:database=imits_migrate;host=deskpro101887.internal.sanger.ac.uk;port=5432
    user = imits
    password = imits
    no_default_attrs = 1
    model = Tarmits::Schema
    <Attributes>
        AutoCommit = 1
        RaiseError = 1
        PrintError = 1
    </Attributes>
</Database>

<Database tarmits_labs>
    dsn = dbi:Pg:database=imits_migrate;host=deskpro101887.internal.sanger.ac.uk;port=5432
    user = imits
    password = imits
    no_default_attrs = 1
    model = Tarmits::Schema
    <Attributes>
        AutoCommit = 1
        RaiseError = 1
        PrintError = 1
    </Attributes>
</Database>

<Database tarmits>
    dsn = dbi:Pg:database=imits_migrate;host=deskpro101887.internal.sanger.ac.uk;port=5432
    user = imits
    password = imits
    no_default_attrs = 1
    model = Tarmits::Schema
    <Attributes>
        AutoCommit = 1
        RaiseError = 1
        PrintError = 1
    </Attributes>
</Database>


4. DBFactory

   Add 'tarmits'       => 'TARMITS_DB', to %ENVVAR_FOR