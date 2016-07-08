package Input::FilteredCoreForeignKeys; 
use strict; 
use warnings; 
our $core_foreign_keys = {
  'seq_region' => {
                    '1' => {
                             'constraint' => '',
                             'col1' => 'coord_system_id',
                             'table2' => 'coord_system',
                             'both_ways' => 0,
                             'col2' => 'coord_system_id'
                           }
                  }
}
;