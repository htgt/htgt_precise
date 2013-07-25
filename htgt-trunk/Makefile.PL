use inc::Module::Install;

name 'HTGT';
all_from 'lib/HTGT.pm';

requires 'Catalyst' => '5.7007';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Cache';
requires 'Catalyst::Plugin::Prototype';
requires 'Catalyst::Plugin::Session::Store::DBI';
requires 'Catalyst::Plugin::Breadcrumbs';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Authentication::Credential::SangerSSO' => '1.0.0';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Model::DBI';
requires 'Catalyst::View::TT';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::Log::Log4perl';
requires 'MooseX::NonMoose' => '0.07';
requires 'Cache::File';
requires 'Template::Plugin::CSV';
requires 'Template::Plugin::JSON';
requires 'Template::Provider::Encoding';
requires 'FCGI::Engine' => '0.11';
requires 'Class::Throwable' => '0.11';
requires 'Template::Plugin::Tree::Simple::View::HTML';
requires 'Module::PortablePath';
requires 'Data::Pageset';
requires 'GD';
requires 'GD::Image::Thumbnail';
requires 'DateTime::Format::Excel';
requires 'Math::Round';
requires 'HTGT::DBFactory' => '1.0';
requires 'HTGT::BioMart::QueryFactory';
requires 'HTGTDB' => '2.1.1';
requires 'FCGI::ProcManager::MaxRequests';
requires 'HTGT::Utils::Report::QCResultsAndPrimers' => '0.100321127';
requires 'HTGT::Utils::Recovery::Report' => '0.101611332';
requires 'HTGT::Utils::BadgerRepository::Pfind' => '1.1010310370';

# Needed by SangerWeb
requires 'XML::FeedLite::Normalised';
requires 'Calendar::Simple';
requires 'iCal::Parser';

requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
