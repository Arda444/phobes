class NovaToolDefinitions {
  const NovaToolDefinitions._();

  static List<Map<String, dynamic>> get tools => [
        {
          'type': 'function',
          'function': {
            'name': 'create_task',
            'description': 'Kullanıcının takvimine yeni TEK bir görev ekler. Birden fazla görev varsa create_multiple_tasks kullan.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {
                  'type': 'string',
                  'description': 'Görevin başlığı (örn: Spora git, Toplantı yap)',
                },
                'date': {
                  'type': 'string',
                  'description': 'Görev tarihi (KESİNLİKLE YYYY-MM-DD formatında olmalı)',
                },
                'time': {
                  'type': 'string',
                  'description': 'Görev saati (KESİNLİKLE HH:MM formatında olmalı)',
                },
              },
              'required': ['title', 'date', 'time'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'create_multiple_tasks',
            'description': 'Kullanıcı birden fazla görev eklemek istediğinde veya haftalık/günlük plan istendiğinde kullanılır. Tüm görevleri tek seferde gönderir.',
            'parameters': {
              'type': 'object',
              'properties': {
                'tasks': {
                  'type': 'array',
                  'description': 'Eklenecek görevlerin listesi (en az 2)',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'title': {'type': 'string', 'description': 'Görev başlığı'},
                      'date': {'type': 'string', 'description': 'Tarih (YYYY-MM-DD)'},
                      'time': {'type': 'string', 'description': 'Saat (HH:MM)'},
                    },
                    'required': ['title', 'date', 'time'],
                  },
                },
              },
              'required': ['tasks'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'create_day_plan',
            'description': 'Belirli bir gün için saatli, detaylı günlük program oluşturur. "Bana bir günlük plan yap", "Yarını planla" gibi isteklerde kullan.',
            'parameters': {
              'type': 'object',
              'properties': {
                'date': {'type': 'string', 'description': 'Planın tarihi (YYYY-MM-DD)'},
                'tasks': {
                  'type': 'array',
                  'description': 'Güne ait görevler (sabahtan akşama doğru sıralı)',
                  'items': {
                    'type': 'object',
                    'properties': {
                      'title': {'type': 'string', 'description': 'Görev/aktivite adı'},
                      'time': {'type': 'string', 'description': 'Saat (HH:MM)'},
                    },
                    'required': ['title', 'time'],
                  },
                },
              },
              'required': ['date', 'tasks'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'ask_user_options',
            'description': 'Kullanıcıya tıklanabilir seçenekler sunar. İstek belirsizse, hangi gün/saat/konu istediğini sormak için kullan. Düz metin soru SORMA — bu aracı çağır.',
            'parameters': {
              'type': 'object',
              'properties': {
                'question': {
                  'type': 'string',
                  'description': 'Kullanıcıya sorulacak kısa soru metni',
                },
                'options': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': '2-5 arası seçenek metinleri (kısa, net)',
                },
              },
              'required': ['question', 'options'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'reschedule_task',
            'description': 'Gizli bağlamda Kimliği (ID) numarası verilen bir görevi, kullanıcının istediği başka bir tarih ve saate erteler.',
            'parameters': {
              'type': 'object',
              'properties': {
                'task_id': {
                  'type': 'string',
                  'description': "Görevin ID'si (Örn: JgX9...)",
                },
                'date': {
                  'type': 'string',
                  'description': 'Yeni tarih (YYYY-MM-DD)',
                },
                'time': {'type': 'string', 'description': 'Yeni saat (HH:MM)'},
              },
              'required': ['task_id', 'date', 'time'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'cancel_task',
            'description': 'Gizli bağlamda Kimliği (ID) numarası verilen bir görevi takvimden siler (iptal eder).',
            'parameters': {
              'type': 'object',
              'properties': {
                'task_id': {
                  'type': 'string',
                  'description': "Silinecek Görevin ID'si",
                },
              },
              'required': ['task_id'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'send_team_announcement',
            'description': 'Gizli bağlamda Kimliği (ID) verilen bir takıma yüksek öncelikli bir duyuru, tavsiye veya mesaj gönderir.',
            'parameters': {
              'type': 'object',
              'properties': {
                'team_id': {
                  'type': 'string',
                  'description': 'Takımın Kimliği (ID)',
                },
                'message': {
                  'type': 'string',
                  'description': 'Gönderilecek duyuru mesajı metni',
                },
              },
              'required': ['team_id', 'message'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'add_subtasks',
            'description': "Belirtilen Görev Kimliği (ID)'sine sahip görevin açıklamasına alt görev maddeleri (markdown checklist) ekler.",
            'parameters': {
              'type': 'object',
              'properties': {
                'task_id': {'type': 'string', 'description': "Görevin ID'si"},
                'subtasks': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Eklenecek alt görevlerin listesi',
                },
              },
              'required': ['task_id', 'subtasks'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'update_task',
            'description': "Görev Kimliği (ID)'si verilen bir görevin başlığını, açıklamasını, tarihini veya saatini günceller.",
            'parameters': {
              'type': 'object',
              'properties': {
                'task_id': {'type': 'string', 'description': "Değiştirilecek görevin ID'si"},
                'title': {'type': 'string', 'description': '(İsteğe bağlı) Yeni başlık'},
                'description': {'type': 'string', 'description': '(İsteğe bağlı) Açıklamaya EKLENECEK metin'},
                'date': {'type': 'string', 'description': '(İsteğe bağlı) Yeni tarih (YYYY-MM-DD)'},
                'time': {'type': 'string', 'description': '(İsteğe bağlı) Yeni başlangıç saati (HH:MM)'},
              },
              'required': ['task_id'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'find_task',
            'description': "Bağlamda ID'si bulunmayan genel bir görevi aratmak ve kullanıcıya özel bir görev kartı çizdirmek için kullanılır.",
            'parameters': {
              'type': 'object',
              'properties': {
                'keyword': {'type': 'string', 'description': 'Görevin isminde geçen kelime veya arama terimi'},
              },
              'required': ['keyword'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'complete_task',
            'description': "Görev ID'si verilen bir görevi tamamlandı olarak işaretler.",
            'parameters': {
              'type': 'object',
              'properties': {
                'task_id': {'type': 'string', 'description': "Tamamlanacak görevin ID'si"},
              },
              'required': ['task_id'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'add_expense',
            'description': 'Kullanıcının bütçesine yeni bir harcama/gider ekler.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Harcamanın konusu'},
                'amount': {'type': 'number', 'description': 'Harcama tutarı'},
                'category': {'type': 'string', 'description': 'Harcama kategorisi (Yemek, Ulaşım, Eğlence, Sağlık, Alışveriş, Faturalar, Diğer)'},
              },
              'required': ['title', 'amount', 'category'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'add_income',
            'description': 'Kullanıcının bütçesine gelir/maaş ekler.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Gelir açıklaması'},
                'amount': {'type': 'number', 'description': 'Gelir tutarı'},
                'category': {'type': 'string', 'description': 'Kategori (Maaş, Freelance, Yatırım, Diğer)'},
              },
              'required': ['title', 'amount', 'category'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'add_savings_goal',
            'description': 'Kullanıcıya yeni bir tasarruf hedefi ekler.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Hedef adı'},
                'target_amount': {'type': 'number', 'description': 'Hedef tutar (TL)'},
                'deadline': {'type': 'string', 'description': 'Son tarih (YYYY-MM-DD)'},
              },
              'required': ['title', 'target_amount'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'mark_medication_taken',
            'description': 'Kullanıcının ilaç içtiğini/aldığını kaydeder.',
            'parameters': {
              'type': 'object',
              'properties': {
                'medication_name': {'type': 'string', 'description': 'İlacın adı'},
                'time': {'type': 'string', 'description': 'İlacın alındığı saat (HH:MM)'},
              },
              'required': ['medication_name', 'time'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'create_appointment',
            'description': 'Kullanıcının takvimine yeni bir randevu/seans ekler.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Randevu başlığı'},
                'client_name': {'type': 'string', 'description': 'Müşteri/danışan adı'},
                'phone': {'type': 'string', 'description': 'Telefon numarası'},
                'date': {'type': 'string', 'description': 'Tarih (YYYY-MM-DD)'},
                'time': {'type': 'string', 'description': 'Saat (HH:MM)'},
                'duration_minutes': {'type': 'integer', 'description': 'Süre (dakika)'},
              },
              'required': ['title', 'client_name', 'date', 'time'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'cancel_appointment',
            'description': "Belirtilen ID'ye sahip randevuyu iptal eder.",
            'parameters': {
              'type': 'object',
              'properties': {
                'appointment_id': {'type': 'string', 'description': "İptal edilecek randevunun ID'si"},
              },
              'required': ['appointment_id'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'reschedule_appointment',
            'description': 'Belirtilen randevuyu farklı tarih/saate taşır.',
            'parameters': {
              'type': 'object',
              'properties': {
                'appointment_id': {'type': 'string', 'description': "Randevunun ID'si"},
                'date': {'type': 'string', 'description': 'Yeni tarih (YYYY-MM-DD)'},
                'time': {'type': 'string', 'description': 'Yeni saat (HH:MM)'},
              },
              'required': ['appointment_id', 'date', 'time'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'create_note',
            'description': 'Kullanıcının not defterine yeni bir not oluşturur.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Not başlığı'},
                'content': {'type': 'string', 'description': 'Not içeriği'},
                'notebook_name': {'type': 'string', 'description': 'Defter adı'},
              },
              'required': ['title', 'content'],
            },
          },
        },
        {
          'type': 'function',
          'function': {
            'name': 'add_habit',
            'description': 'Kullanıcının alışkanlık listesine yeni bir alışkanlık ekler.',
            'parameters': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string', 'description': 'Alışkanlık adı'},
                'reminder_time': {'type': 'string', 'description': 'Günlük hatırlatma saati (HH:MM)'},
              },
              'required': ['title'],
            },
          },
        },
      ];
}
