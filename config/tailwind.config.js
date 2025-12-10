module.exports = {
  content: ["./app/views/**/*.html.erb", "./app/helpers/**/*.rb", "./app/javascript/**/*.js"],
  theme: {
    extend: {
      colors: {
        espresso: "#1B1A17",
        "espresso-light": "#252320",
        deshojo: "#B93E3E",
        cream: "#F6F1EB",
        "coffee-brown": "#4A2F27",
        moss: "#78866B",
      },
      fontFamily: {
        serif: ["Cormorant Garamond", "Georgia", "serif"],
        sans: ["Inter", "system-ui", "sans-serif"],
      },
      borderRadius: {
        brand: "6px",
        card: "8px",
        modal: "12px",
        badge: "4px",
      },
      boxShadow: {
        minimal: "0 1px 2px rgba(0, 0, 0, 0.3)",
      },
    },
  },
  plugins: [],
};
