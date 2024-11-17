module BlockchainTicketResalePlateform::TicketMarket {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;

    /// Error codes
    const ETICKET_NOT_FOUND: u64 = 1;
    const ETICKET_ALREADY_LISTED: u64 = 2;
    const EINVALID_PRICE: u64 = 3;

    /// Struct representing a ticket listing
    struct TicketListing has store, key {
        tickets: vector<Ticket>,
    }

    /// Struct representing a single ticket
    struct Ticket has store {
        ticket_id: u64,
        price: u64,
        is_listed: bool,
    }

    /// Function to list a ticket for resale
    public fun list_ticket(
        seller: &signer,
        ticket_id: u64,
        price: u64
    ) acquires TicketListing {
        assert!(price > 0, EINVALID_PRICE);
        
        let seller_addr = signer::address_of(seller);
        if (!exists<TicketListing>(seller_addr)) {
            move_to(seller, TicketListing { tickets: vector::empty() });
        };
        
        let listing = borrow_global_mut<TicketListing>(seller_addr);
        let ticket = Ticket {
            ticket_id,
            price,
            is_listed: true,
        };
        vector::push_back(&mut listing.tickets, ticket);
    }

    /// Function to purchase a listed ticket
    public fun purchase_ticket(
        buyer: &signer,
        seller: address,
        ticket_id: u64
    ) acquires TicketListing {
        let listing = borrow_global_mut<TicketListing>(seller);
        let len = vector::length(&listing.tickets);
        let idx = 0;
        
        while (idx < len) {
            let ticket = vector::borrow(&listing.tickets, idx);
            if (ticket.ticket_id == ticket_id && ticket.is_listed) {
                let payment = coin::withdraw<AptosCoin>(buyer, ticket.price);
                coin::deposit(seller, payment);
                break
            };
            idx = idx + 1;
        };
    }
}