module sui_vote::sui_vote;

use std::string;
use sui::display;
use sui::event;
use sui::package;
use sui::url::{Self, Url};

public struct Event has key, store {
    id: UID,
    author: address,
    name: string::String,
}

public struct Vote has key, store {
    id: UID,
    author: address,
    vote: vector<u8>,
    event: ID,
    candidate_id: u8,
}

public struct NFT has key, store {
    id: object::UID,
    name: string::String,
    description: string::String,
    image_url: Url,
}

public struct Mint_Event has copy, drop {
    object_id: ID,
    creator: address,
    name: string::String,
}

public struct SUI_VOTE has drop {}

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

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
}

entry fun create_event(event_name: string::String, ctx: &mut TxContext) {
    let event_obj = Event {
        id: object::new(ctx),
        author: ctx.sender(),
        name: event_name,
    };

    transfer::transfer(event_obj, ctx.sender());
}

entry fun place_vote(vote: vector<u8>, event: &Event, candidate_id: u8, ctx: &mut TxContext) {
    let vote_obj = Vote {
        id: object::new(ctx),
        author: ctx.sender(),
        vote: vote,
        event: object::uid_to_inner(&event.id),
        candidate_id: candidate_id,
    };
    transfer::transfer(vote_obj, ctx.sender());

    let image_url =
        b"https://lh6.googleusercontent.com/proxy/n7vPSNktv5P40N2qecM3ctzWrU4xwxgMTUXKZURRwFKlrTAK0POh2NecZi6oJgadTtw6YLSP5r9HYcjfq1Hp1wNqOayoYo4EAQ9Xe0Klc7vXHptRdekGwDkugEBQAImi";

    let nft = mint(
        b"Voted",
        b"This is to certify that you have successfully voted!",
        image_url,
        ctx,
    );
    transfer::public_transfer(nft, ctx.sender());
}

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

    return nft
}

entry fun remove_vote(vote: Vote, ctx: &TxContext) {
    let Vote { id, author, .. } = vote;

    assert!(author == ctx.sender(), 401);
    object::delete(id);
}
