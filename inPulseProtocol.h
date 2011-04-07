/* Definitions for endpoint numbers */
#define PP_ENDPOINT_CONTROL 0
#define PP_ENDPOINT_NOTIFICATION 1
#define PP_ENDPOINT_COMMAND 2
#define PP_ENDPOINT_SPIFLASH 3

enum commands
{
	command_query_vitals			   = 0,
	command_read_setting			   = 1,
	command_write_setting		       = 2,
	command_erase_spiflash_sector	   = 32,
	command_enable_unsafe_spiflash_ops = 33,
	command_erase_element			   = 40,
	command_set_time			       = 50,
	command_reboot_watch		       = 255,
};

typedef struct
{
    // Type equals 1 for vibrate, others are undefined
    // On and off times specified are in units of 10ms.
    // Example: on1 = 10 will vibrate for 100ms.
    uint8_t type;
    uint8_t vibe_intensity; // not used yet (range 0 — 255)
    uint8_t unused_field2;
    uint8_t unused_field1;
    uint8_t unused_field0;
    uint8_t on1;
    uint8_t off1;
    uint8_t on2;
    uint8_t off2;
    uint8_t on3;
    uint8_t off3;
    uint8_t on4;
} __attribute__((packed)) pp_alert_configuration_t;

typedef struct {
	uint8_t header_length;
	uint8_t endpoint;
	uint16_t length;
	time_t time;
} __attribute__((packed)) message_header;

typedef struct {
	message_header message_header;
	uint16_t command;
	uint32_t parameter1;
	uint32_t parameter2;
} __attribute__((packed)) command_query_header;

typedef struct {
	message_header message_header;
	uint32_t	notification_type;  // The type of notification (e-mail/sms/ calender/phone).
	pp_alert_configuration_t	pp_alert_configuration_t;		// Bitmask of hardware alerts to activate (flash/double flash/vibrate/double vibrate)
} __attribute__((packed)) notification_message_header;

hci_con_handle_t con_handle;
uint16_t source_cid_interrupt;
uint16_t source_cid_control;
uint16_t source_cid;
