use dep::aztec::protocol_types::{address::AztecAddress, traits::{Serialize, Deserialize}};

// Sell Offer Public struct
struct Offer {
    seller: AztecAddress,
    amount: u8,
    for_amount: u8,
    status: bool
}

global OFFER_SERIALIZED_LEN: Field = 4;

impl Deserialize<OFFER_SERIALIZED_LEN> for Offer {
    fn deserialize(fields: [Field; OFFER_SERIALIZED_LEN]) -> Self {
        Offer { seller: AztecAddress::from_field(fields[0]), amount: fields[1] as u8, for_amount: fields[2] as u8, status: fields[3]}
    }
}

impl Serialize<OFFER_SERIALIZED_LEN> for Offer {
    fn serialize(self) -> [Field; OFFER_SERIALIZED_LEN] {
        [self.seller.to_field(), self.amount as Field, self.for_amount as Field, self.status]
    }
}
