mod types;

contract OTCContract {

    // Imports
    use dep::aztec::{
        protocol_types::{abis::function_selector::FunctionSelector, address::AztecAddress},
        state_vars::{Map, PrivateSet, PublicImmutable, SharedImmutable}
    };
    use dep::value_note::value_note::ValueNote;
    use dep::token::Token;

    use crate::types::{offer::Offer};


    // Storage 
    #[aztec(storage)]
    struct Storage {
        // Sell Token used for OTC listings
        sell_token: SharedImmutable<AztecAddress>,
        // Settlement Token used by the Buyer to pay for the Sell Token
        settlement_token: SharedImmutable<AztecAddress>,
        // OTC Marketplace operator
        operator: SharedImmutable<AztecAddress>,
        // counter to track offer IDs
        offer_id_counter: PublicMutable<u64>,
        // Mapping of sell_token to offers
        offers: Map<u64, PublicMutable<Offer>>,
        // Pending settlements for sellers to claim
        pending_settlements: PrivateSet<ValueNote>,
    }

    // Functions
    #[aztec(public)]
    #[aztec(initializer)]
    fn constructor(sell_token: AztecAddress, settlement_token: AztecAddress, operator: AztecAddress) {
        storage.sell_token.initialize(sell_token);
        storage.settlement_token.initialize(settlement_token);
        storage.operator.initialize(operator);
        storage.offer_id_counter.initialize(0);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _increment() -> pub u64 {
        let counter = storage.offer_id_counter.read() + 1;
        storage.offer_id_counter.write(counter);
        counter
    }

    #[aztec(private)]
    fn create_offer(amount: u8, for_amount: u8) {
        // Check token balance for user
        let balance = Token::at(storage.sell_token.read_private()).balance_of_private(
            context.msg_sender()
        ).call(&mut context);

        assert(balance as u8 > amount as u8, "private token balance is less than amount");
        
        // Deposit sell_token to OTC contract
        Token::at(storage.sell_token.read_private()).transfer(
            context.msg_sender(),
            context.this_address(),
            amount as Field,
            0
        ).call(&mut context);

        // Create and offer to offers mapping
        let mut offer = Offer { seller: context.msg_sender(), amount,  for_amount, false};

        let offer_id = OTCContract::at(context.this_address())._increment().enqueue(&mut context);

        storage.offers.at(offer_id).write(&mut offer);

        // 3) Create a value note for the seller so that he can later on claim a rewards token in the Claim
        // contract by proving that the hash of this note exists in the note hash tree.
        // let mut note = ValueNote::new(amount as Field, context.msg_sender());
        // storage.pending_settlements.insert(&mut note, true);
    }

    #[aztec(private)]
    fn accept_offer(offer_id: u64)  {
        // Check that Offer exists and has not been fulfilled
        let offer = storage.offers.at(offer_id).read();

        assert(offer.status == false, "Offer is no longer available");

        // Check token balance for user
        let balance = Token::at(storage.settlement_token.read_private()).balance_of_private(
            context.msg_sender()
        ).call(&mut context);


        assert(balance as u8 > amount as u8, "private token balance is less than amount");

        // TODO: Change status of offer ie nullify the note
        // make sure the change takes effect
        offer.status == true;
        // NOT COMPLETE, update the Offer

        amount = offer.amount;
        for_amount = offer.for_amount;
        
        // Transfer settlement_token to seller
        Token::at(storage.settlement_token.read_private()).transfer(
            context.msg_sender(),
            context.this_address(),
            for_amount as Field,
            0
        ).call(&mut context);


        // Transfer sell_token from OTC Contract to buyer
        Token::at(storage.sell_token.read_private()).transfer(
            context.this_address(),
            context.msg_sender(),
            amount as Field,
            0
        ).call(&mut context);

    }

    unconstrained fn view_all_offers() -> [Offer] {
        offers = [];
        counter = storage.offer_id_counter.read()
        for i in 0..counter {            
            offers[i + 1] = storage.offers.at(i + 1).read();   
        }
        offers
    }

    unconstrained fn view_unfulfilled_offers() -> [Offer] {
        offers = [];
        counter = storage.offer_id_counter.read()
        for i in 0..counter {
            let offer = storage.offers.at(i + 1).read();
            
            if offer.status {
                continue;
            } else {
                offers[i + 1] = storage.offers.at(i + 1).read();
            }    
        }
        offers
    }
}
