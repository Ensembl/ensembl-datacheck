package Input::FilteredCoreForeignKeys; 
use strict; 
use warnings; 
our $core_foreign_keys = {
  'protein_feature' => {
                         '1' => {
                                  'col2' => 'translation_id',
                                  'both_ways' => 0,
                                  'col1' => 'translation_id',
                                  'table2' => 'translation',
                                  'constraint' => ''
                                }
                       },
  'object_xref' => {
                     '1' => {
                              'col1' => 'xref_id',
                              'table2' => 'xref',
                              'both_ways' => 0,
                              'col2' => 'xref_id',
                              'constraint' => ''
                            }
                   },
  'unmapped_object' => {
                         '3' => {
                                  'both_ways' => 0,
                                  'col2' => 'external_db_id',
                                  'col1' => 'external_db_id',
                                  'table2' => 'external_db',
                                  'constraint' => ''
                                }
                       },
  'xref' => {
              '1' => {
                       'constraint' => '',
                       'table2' => 'external_db',
                       'col1' => 'external_db_id',
                       'both_ways' => 0,
                       'col2' => 'external_db_id'
                     }
            },
  'peptide_archive' => {
                         '1' => {
                                  'constraint' => '',
                                  'col2' => 'peptide_archive_id',
                                  'both_ways' => 0,
                                  'table2' => 'gene_archive',
                                  'col1' => 'peptide_archive_id'
                                }
                       },
  'alt_allele' => {
                    '1' => {
                             'col2' => 'gene_id',
                             'both_ways' => 0,
                             'col1' => 'gene_id',
                             'table2' => 'gene',
                             'constraint' => ''
                           }
                  },
  'marker_synonym' => {
                        '1' => {
                                 'constraint' => '',
                                 'col2' => 'marker_id',
                                 'both_ways' => 0,
                                 'table2' => 'marker',
                                 'col1' => 'marker_id'
                               }
                      },
  'transcript_supporting_feature' => {
                                       '1' => {
                                                'col2' => 'dna_align_feature_id',
                                                'both_ways' => 0,
                                                'col1' => 'feature_id',
                                                'table2' => 'dna_align_feature',
                                                'constraint' => 'transcript_supporting_feature.feature_type = \'dna_align_feature\''
                                              },
                                       '2' => {
                                                'both_ways' => 0,
                                                'col2' => 'protein_align_feature_id',
                                                'col1' => 'feature_id',
                                                'table2' => 'protein_align_feature',
                                                'constraint' => undef
                                              }
                                     },
  'transcript' => {
                    '1' => {
                             'table2' => 'exon_transcript',
                             'col1' => 'transcript_id',
                             'col2' => 'transcript_id',
                             'both_ways' => 1,
                             'constraint' => ''
                           }
                  },
  'misc_attrib' => {
                     '1' => {
                              'constraint' => '',
                              'table2' => 'attrib_type',
                              'col1' => 'attrib_type_id',
                              'col2' => 'attrib_type_id',
                              'both_ways' => 0
                            }
                   },
  'gene_archive' => {
                      '2' => {
                               'constraint' => '',
                               'table2' => 'mapping_session',
                               'col1' => 'mapping_session_id',
                               'col2' => 'mapping_session_id',
                               'both_ways' => 0
                             },
                      '1' => {
                               'constraint' => 'gene_archive.peptide_archive_id != 0',
                               'col2' => 'peptide_archive_id',
                               'both_ways' => 0,
                               'table2' => 'peptide_archive',
                               'col1' => 'peptide_archive_id'
                             }
                    },
  'identity_xref' => {
                       '1' => {
                                'table2' => 'object_xref',
                                'col1' => 'object_xref_id',
                                'both_ways' => 0,
                                'col2' => 'object_xref_id',
                                'constraint' => ''
                              }
                     },
  'density_feature' => {
                         '1' => {
                                  'col2' => 'density_type_id',
                                  'both_ways' => 0,
                                  'col1' => 'density_type_id',
                                  'table2' => 'density_type',
                                  'constraint' => ''
                                }
                       },
  'marker' => {
                '1' => {
                         'col2' => 'marker_synonym_id',
                         'both_ways' => 0,
                         'table2' => 'marker_synonym',
                         'col1' => 'display_marker_synonym_id',
                         'constraint' => ''
                       }
              },
  'gene_attrib' => {
                     '1' => {
                              'both_ways' => 0,
                              'col2' => 'attrib_type_id',
                              'col1' => 'attrib_type_id',
                              'table2' => 'attrib_type',
                              'constraint' => ''
                            }
                   },
  'assembly' => {
                  '1' => {
                           'constraint' => '',
                           'both_ways' => 0,
                           'col2' => 'seq_region_id',
                           'table2' => 'seq_region',
                           'col1' => 'asm_seq_region_id'
                         },
                  '2' => {
                           'both_ways' => 0,
                           'col2' => 'seq_region_id',
                           'table2' => 'seq_region',
                           'col1' => 'cmp_seq_region_id',
                           'constraint' => ''
                         }
                },
  'marker_map_location' => {
                             '2' => {
                                      'table2' => 'marker',
                                      'col1' => 'marker_id',
                                      'both_ways' => 0,
                                      'col2' => 'marker_id',
                                      'constraint' => ''
                                    }
                           },
  'translation' => {
                     '1' => {
                              'col2' => 'transcript_id',
                              'both_ways' => 0,
                              'table2' => 'transcript',
                              'col1' => 'transcript_id',
                              'constraint' => ''
                            }
                   },
  'analysis_description' => {
                              '1' => {
                                       'col1' => 'analysis_id',
                                       'table2' => 'analysis',
                                       'both_ways' => 0,
                                       'col2' => 'analysis_id',
                                       'constraint' => ''
                                     }
                            },
  'external_synonym' => {
                          '1' => {
                                   'table2' => 'xref',
                                   'col1' => 'xref_id',
                                   'both_ways' => 0,
                                   'col2' => 'xref_id',
                                   'constraint' => ''
                                 }
                        },
  'associated_xref' => {
                         '2' => {
                                  'constraint' => '',
                                  'col1' => 'xref_id',
                                  'table2' => 'xref',
                                  'both_ways' => 0,
                                  'col2' => 'xref_id'
                                },
                         '3' => {
                                  'col1' => 'source_xref_id',
                                  'table2' => 'xref',
                                  'both_ways' => 0,
                                  'col2' => 'xref_id',
                                  'constraint' => ''
                                },
                         '1' => {
                                  'constraint' => '',
                                  'both_ways' => 0,
                                  'col2' => 'object_xref_id',
                                  'col1' => 'object_xref_id',
                                  'table2' => 'object_xref'
                                }
                       },
  'prediction_exon' => {
                         '1' => {
                                  'constraint' => '',
                                  'col2' => 'prediction_transcript_id',
                                  'both_ways' => 0,
                                  'table2' => 'prediction_transcript',
                                  'col1' => 'prediction_transcript_id'
                                }
                       },
  'seq_region_attrib' => {
                           '1' => {
                                    'constraint' => '',
                                    'table2' => 'seq_region',
                                    'col1' => 'seq_region_id',
                                    'col2' => 'seq_region_id',
                                    'both_ways' => 0
                                  }
                         },
  'misc_feature_misc_set' => {
                               '1' => {
                                        'constraint' => '',
                                        'both_ways' => 0,
                                        'col2' => 'misc_feature_id',
                                        'table2' => 'misc_feature',
                                        'col1' => 'misc_feature_id'
                                      },
                               '2' => {
                                        'constraint' => '',
                                        'both_ways' => 0,
                                        'col2' => 'misc_set_id',
                                        'col1' => 'misc_set_id',
                                        'table2' => 'misc_set'
                                      }
                             },
  'dna' => {
             '1' => {
                      'constraint' => '',
                      'col2' => 'seq_region_id',
                      'both_ways' => 0,
                      'col1' => 'seq_region_id',
                      'table2' => 'seq_region'
                    }
           },
  'stable_id_event' => {
                         '1' => {
                                  'constraint' => '',
                                  'both_ways' => 0,
                                  'col2' => 'mapping_session_id',
                                  'col1' => 'mapping_session_id',
                                  'table2' => 'mapping_session'
                                }
                       },
  'ontology_xref' => {
                       '1' => {
                                'constraint' => '',
                                'col1' => 'object_xref_id',
                                'table2' => 'object_xref',
                                'col2' => 'object_xref_id',
                                'both_ways' => 0
                              }
                     },
  'translation_attrib' => {
                            '2' => {
                                     'table2' => 'attrib_type',
                                     'col1' => 'attrib_type_id',
                                     'col2' => 'attrib_type_id',
                                     'both_ways' => 0,
                                     'constraint' => ''
                                   }
                          },
  'transcript_attrib' => {
                           '2' => {
                                    'constraint' => '',
                                    'col1' => 'attrib_type_id',
                                    'table2' => 'attrib_type',
                                    'both_ways' => 0,
                                    'col2' => 'attrib_type_id'
                                  }
                         },
  'seq_region' => {
                    '1' => {
                             'col1' => 'coord_system_id',
                             'table2' => 'coord_system',
                             'col2' => 'coord_system_id',
                             'both_ways' => 0,
                             'constraint' => ''
                           }
                  },
  'marker_feature' => {
                        '1' => {
                                 'both_ways' => 0,
                                 'col2' => 'marker_id',
                                 'col1' => 'marker_id',
                                 'table2' => 'marker',
                                 'constraint' => ''
                               }
                      },
  'exon' => {
              '1' => {
                       'col1' => 'exon_id',
                       'table2' => 'exon_transcript',
                       'both_ways' => 1,
                       'col2' => 'exon_id',
                       'constraint' => ''
                     }
            },
  'supporting_feature' => {
                            '3' => {
                                     'constraint' => 'supporting_feature.feature_type = \'protein_align_feature\'',
                                     'both_ways' => 0,
                                     'col2' => 'protein_align_feature_id',
                                     'table2' => 'protein_align_feature',
                                     'col1' => 'feature_id'
                                   }
                          },
  'dependent_xref' => {
                        '1' => {
                                 'constraint' => '',
                                 'both_ways' => 0,
                                 'col2' => 'object_xref_id',
                                 'table2' => 'object_xref',
                                 'col1' => 'object_xref_id'
                               },
                        '3' => {
                                 'constraint' => '',
                                 'table2' => 'xref',
                                 'col1' => 'dependent_xref_id',
                                 'col2' => 'xref_id',
                                 'both_ways' => 0
                               },
                        '2' => {
                                 'both_ways' => 0,
                                 'col2' => 'xref_id',
                                 'col1' => 'master_xref_id',
                                 'table2' => 'object_xref',
                                 'constraint' => ''
                               }
                      },
  'gene' => {
              '1' => {
                       'constraint' => '',
                       'col2' => 'gene_id',
                       'both_ways' => 1,
                       'col1' => 'gene_id',
                       'table2' => 'transcript'
                     }
            },
  'assembly_exception' => {
                            '2' => {
                                     'constraint' => '',
                                     'table2' => 'seq_region',
                                     'col1' => 'exc_seq_region_id',
                                     'col2' => 'seq_region_id',
                                     'both_ways' => 0
                                   },
                            '1' => {
                                     'table2' => 'seq_region',
                                     'col1' => 'seq_region_id',
                                     'col2' => 'seq_region_id',
                                     'both_ways' => 0,
                                     'constraint' => ''
                                   }
                          }
}
;