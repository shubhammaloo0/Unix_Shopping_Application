#!/bin/bash

# Create user data directory if it doesn't exist
USER_DATA_DIR="user_data"
mkdir -p "$USER_DATA_DIR"

USER_DATA_FILE="$USER_DATA_DIR/user_data.txt"
PRODUCTS_FILE="products.txt"
SHOPPING_CART_FILE=""
ORDERS_DIR="orders"
LOGGED_IN_USER=""

# Function to handle user signup
signup() {
    username=$(zenity --entry --title="Signup" --text="Enter your username:" --width=400 --height=300)

    # Check if the username already exists
    if grep -q "^$username:" "$USER_DATA_FILE"; then
        zenity --error --title="Signup Failed" --text="Username already exists. Please choose a different username." --width=400 --height=300
        return 1
    fi

    password=$(zenity --password --title="Signup" --text="Enter your password:" --width=400 --height=300)

    # Store username and password in the user_data.txt file
    echo "$username:$password" >> "$USER_DATA_FILE"
    
    zenity --info --title="Signup Successful" --text="Signup successful! You can now log in." --width=400 --height=300
}

# Function to handle user login
login() {
    username=$(zenity --entry --title="Login" --text="Enter your username:" --width=400 --height=300)

    # Check if the username exists
    if grep -q "^$username:" "$USER_DATA_FILE"; then
        password=$(zenity --password --title="Login" --text="Enter your password:" --width=400 --height=300)

        # Validate the password
        if grep -q "^$username:$password" "$USER_DATA_FILE"; then
            LOGGED_IN_USER="$username"
            USER_DIR="user_data/$username"
            mkdir -p "$USER_DIR"
            SHOPPING_CART_FILE="$USER_DIR/cart.txt"
            echo "User directory set to: $USER_DIR"
            echo "Shopping cart file set to: $SHOPPING_CART_FILE"
            zenity --info --title="Login Successful" --text="Welcome, $username!" --width=400 --height=300
            return 0
        else
            zenity --error --title="Login Failed" --text="Incorrect password. Please try again." --width=400 --height=300
            return 1
        fi
    else
        zenity --error --title="Login Failed" --text="Username not found. Please sign up first." --width=400 --height=300
        return 1
    fi
}

# Function to display product listing using Zenity
display_products() {
    types=$(awk -F: '{print $NF}' "$PRODUCTS_FILE" | sort | uniq)
    selected_type=$(zenity --list --title="Select Product Type" --column="Product Type" $types --width=600 --height=500)
    products_text=""
    while IFS=: read -r product_id name price quantity type; do
        if [ "$type" == "$selected_type" ]; then
            products_text+="Product ID: $product_id\nName: $name\nPrice: $price\nQuantity: $quantity\n\n"
        fi
    done < "$PRODUCTS_FILE"

    zenity --text-info --title="Product Listing - $selected_type" --width=800 --height=500 --filename=<(echo -e "$products_text")
}

# Function to add items to the shopping cart
add_to_cart() {
    product_id=$(zenity --entry --title="Add to Cart" --text="Enter the product ID:" --width=400 --height=300)
    quantity=$(zenity --entry --title="Add to Cart" --text="Enter the quantity:" --width=400 --height=300)

    if grep -q "^$product_id:" "$PRODUCTS_FILE"; then
        echo "$product_id:$quantity" >> "$SHOPPING_CART_FILE"
        zenity --info --title="Added to Cart" --text="Item added to your cart." --width=400 --height=300
    else
        zenity --error --title="Error" --text="Invalid product ID." --width=400 --height=300
    fi
}

# Function to display and checkout the shopping cart
checkout() {
    cart_file="$SHOPPING_CART_FILE"
    total=0
    while IFS=: read -r product_id quantity; do
        name=$(grep "^$product_id:" "$PRODUCTS_FILE" | cut -d: -f2)
        price=$(grep "^$product_id:" "$PRODUCTS_FILE" | cut -d: -f3)
        subtotal=$((quantity * price))
        total=$((total + subtotal))
        echo "$product_id. $name - $quantity x $price = $subtotal"
    done < "$cart_file"

    if [ "$total" -eq 0 ]; then
        zenity --info --title="Shopping Cart" --text="Your shopping cart is empty." --width=400 --height=300
    else
        address=$(zenity --entry --title="Checkout - Enter Address" --text="Enter your address:" --width=400 --height=300)
        if [ -z "$address" ]; then
            zenity --error --title="Error" --text="Address cannot be empty." --width=400 --height=300
        else
            # Create order directory if it doesn't exist
            mkdir -p "$ORDERS_DIR/$LOGGED_IN_USER"
            
            # Save order details to a file
            order_file="$ORDERS_DIR/$LOGGED_IN_USER/$(date +'%Y%m%d%H%M%S').txt"
            echo "Address: $address" > "$order_file"
            echo "Items:" >> "$order_file"
            while IFS=: read -r product_id quantity; do
                name=$(grep "^$product_id:" "$PRODUCTS_FILE" | cut -d: -f2)
                echo "  - $name x $quantity" >> "$order_file"
            done < "$cart_file"
            
            # Clear the shopping cart
            rm "$cart_file"
            
            zenity --info --title="Checkout Successful" --text="Thank you for your order! Total amount: $total\nYour order has been placed successfully." --width=400 --height=300
        fi
    fi
}



# Function to view the shopping cart
view_cart() {
    cart_file="$SHOPPING_CART_FILE"
    if [ -s "$cart_file" ]; then
        zenity --text-info --title="Shopping Cart" --filename="$cart_file" --width=600 --height=400
    else
        zenity --info --title="Shopping Cart" --text="Your shopping cart is empty." --width=400 --height=300
    fi
}

# Main menu
while true; do
    if [ -z "$LOGGED_IN_USER" ]; then
        choice=$(zenity --list --title="Main Menu" --column="Options" "Login" "Signup" "Exit" --width=500 --height=400)
        
        case $choice in
            "Login")
                login
                ;;
            "Signup")
                signup
                ;;
            "Exit")
                zenity --info --title="Exit" --text="Exiting..." --width=400 --height=300
                exit 0
                ;;
            *)
                zenity --error --title="Invalid Option" --text="Invalid option. Please choose a valid option." --width=400 --height=300
                ;;
        esac
    else
        choice=$(zenity --list --title="Main Menu" --column="Options" "Display Products" "Add to Cart" "Checkout" "View Cart" "Logout" --width=400 --height=300)
        
        case $choice in
            "Display Products")
                display_products
                ;;
            "Add to Cart")
                add_to_cart
                ;;
            "Checkout")
                checkout
                ;;
            "View Cart")
                view_cart
                ;;
            "Logout")
                LOGGED_IN_USER=""
                zenity --info --title="Logout" --text="Logging out..." --width=400 --height=300
                ;;
            *)
                zenity --error --title="Invalid Option" --text="Invalid option. Please choose a valid option." --width=400 --height=300
                ;;
        esac
    fi
done
