# Project 1 Server API Guide

This document provides a guide to the API endpoints for the Project 1 server.

## Authentication

### `POST /api/login`

Authenticates a user with email and password.

**Request Body:**

*   `email` (string, required): The user's email.
*   `password` (string, required): The user's password, base64 encoded and encrypted.

**Response:**

*   `token` (string): A JWT token for authenticating subsequent requests.
*   `user` (object):
    *   `id` (integer): The user's ID.
    *   `email` (string): The user's email.

### `POST /api/guest_login`

Creates a guest user and returns a JWT token.

**Request Body:**

*   `device_id` (string, required): The device ID of the guest user.

**Response:**

*   `id` (integer): The player's ID.

## Allies

### `GET /api/allies`

Retrieves a list of all allies.

**Response:**

*   `success` (boolean): Indicates if the request was successful.
*   `data` (object):
    *   `characters` (array): A list of ally objects.
        *   `id` (integer): The ally's ID.
        *   `name` (string): The ally's name.
        *   `fragment_name` (string): The name of the ally's fragment.

### `GET /api/allies/:ally_id/upgrade_levels`

Retrieves the upgrade levels for a specific ally.

**Path Parameters:**

*   `ally_id` (string, required): The fragment name of the ally.

**Response:**

*   `ally_id` (string): The fragment name of the ally.
*   `name` (string): The ally's name.
*   `cn_name` (string): The ally's name in Chinese.
*   `current_level` (integer): The current level of the ally (placeholder, always 1).
*   `upgrade_levels` (array): A list of upgrade level objects.
    *   `level` (string): The level identifier (e.g., "L01").
    *   `description` (string): The description of the upgrade.
    *   `cost` (integer): The cost of the upgrade.
    *   `is_unlocked` (boolean): Indicates if the upgrade is unlocked.

### `GET /api/gem-levels`

Retrieves the available gem levels.

**Response:**

*   `success` (boolean): Indicates if the request was successful.
*   `data` (object):
    *   `gem_levels` (array): A list of gem level objects.
        *   `level` (integer): The gem level.
        *   `id` (string): The gem ID (e.g., "Gem_01").
        *   `name` (string): The name of the gem level.

### `GET /api/level_up_costs`

Retrieves the costs for leveling up.

**Response:**

*   `level_up_costs` (array): A list of level up cost objects.
    *   `level` (integer): The level.
    *   `skillbook_cost` (integer): The cost in skillbooks.
    *   `gold_cost` (integer): The cost in gold.

## Other

### `GET /up`

A health check endpoint that returns `200 OK` if the server is running.

### `GET /test`

A test endpoint that broadcasts a message "test" to the `Battle_1` Action Cable channel.

### WebSocket

The server exposes a WebSocket endpoint at `/cable` for real-time communication.
