module sui_vote::sui_vote;

use std::string;
use sui::display;
use sui::event;
use sui::package;
use sui::table;
use sui::url::{Self, Url};

/// Event object, stores voters in a table
public struct Event has key, store {
    id: UID,
    author: address,
    name: string::String,
    voters: table::Table<address, bool>,
}

public struct Vote has key, store {
    id: UID,
    author: address,
    vote: vector<u8>,
    event: ID,
    candidate_id: u8,
}

public struct NFT has key, store {
    id: UID,
    name: string::String,
    description: string::String,
    image_url: Url,
}

/// Event emitted when minting NFT
public struct Mint_Event has copy, drop {
    object_id: ID,
    creator: address,
    name: string::String,
}

public struct SUI_VOTE has drop {}

/// Initialize the module and set up display for NFT
fun init(witness: SUI_VOTE, ctx: &mut TxContext) {
    let publisher = package::claim(witness, ctx);

    let keys = vector[
        string::utf8(b"name"),
        string::utf8(b"description"),
        string::utf8(b"image_url"),
        string::utf8(b"creator"),
    ];

    let values = vector[
        string::utf8(b"{name}"),
        string::utf8(b"{description}"),
        string::utf8(b"{image_url}"),
        string::utf8(b"GCTU Voting System"),
    ];

    let mut display = display::new_with_fields<NFT>(
        &publisher,
        keys,
        values,
        ctx,
    );

    display::update_version(&mut display);

    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(display, tx_context::sender(ctx));
}

/// Create a new voting event
entry fun create_event(event_name: string::String, ctx: &mut TxContext) {
    let event_obj = Event {
        id: object::new(ctx),
        author: tx_context::sender(ctx),
        name: event_name,
        voters: table::new<address, bool>(ctx),
    };

    transfer::transfer(event_obj, tx_context::sender(ctx));
}

/// Place a vote for a candidate in an event
entry fun place_vote(vote: vector<u8>, event: &mut Event, candidate_id: u8, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);
    if (table::contains(&event.voters, sender)) {
        // Abort if already voted
        abort 300
    };

    let vote_obj = Vote {
        id: object::new(ctx),
        author: sender,
        vote: vote,
        event: object::uid_to_inner(&event.id),
        candidate_id: candidate_id,
    };
    transfer::transfer(vote_obj, sender);

    let image_url =
        b"https://lh6.googleusercontent.com/proxy/n7vPSNktv5P40N2qecM3ctzWrU4xwxgMTUXKZURRwFKlrTAK0POh2NecZi6oJgadTtw6YLSP5r9HYcjfq1Hp1wNqOayoYo4EAQ9Xe0Klc7vXHptRdekGwDkugEBQAImi";

    let nft = mint(
        b"Voted",
        b"This is to certify that you have successfully voted!",
        image_url,
        ctx,
    );
    table::add(&mut event.voters, sender, true);
    transfer::public_transfer(nft, sender);
}

/// Mint an NFT for the voter
public fun mint(
    name: vector<u8>,
    description: vector<u8>,
    image_url: vector<u8>,
    ctx: &mut TxContext,
): NFT {
    let nft = NFT {
        id: object::new(ctx),
        name: string::utf8(name),
        description: string::utf8(description),
        image_url: url::new_unsafe_from_bytes(image_url),
    };

    let sender = tx_context::sender(ctx);

    event::emit(Mint_Event {
        object_id: object::uid_to_inner(&nft.id),
        creator: sender,
        name: nft.name,
    });

    nft
}

/// Remove a vote
entry fun remove_vote(vote: Vote, ctx: &TxContext) {
    let Vote { id, author, .. } = vote;

    assert!(author == tx_context::sender(ctx), 401);
    object::delete(id);
}
