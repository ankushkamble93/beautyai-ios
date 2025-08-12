import SwiftUI
import PhotosUI
import Supabase
import Foundation

// MARK: - Country Code Data
struct CountryCode: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
    let dialCode: String
    
    static let allCountries: [CountryCode] = [
        CountryCode(name: "United States", code: "US", flag: "🇺🇸", dialCode: "+1"),
        CountryCode(name: "Canada", code: "CA", flag: "🇨🇦", dialCode: "+1"),
        CountryCode(name: "United Kingdom", code: "GB", flag: "🇬🇧", dialCode: "+44"),
        CountryCode(name: "India", code: "IN", flag: "🇮🇳", dialCode: "+91"),
        CountryCode(name: "Australia", code: "AU", flag: "🇦🇺", dialCode: "+61"),
        CountryCode(name: "Germany", code: "DE", flag: "🇩🇪", dialCode: "+49"),
        CountryCode(name: "France", code: "FR", flag: "🇫🇷", dialCode: "+33"),
        CountryCode(name: "Japan", code: "JP", flag: "🇯🇵", dialCode: "+81"),
        CountryCode(name: "South Korea", code: "KR", flag: "🇰🇷", dialCode: "+82"),
        CountryCode(name: "Brazil", code: "BR", flag: "🇧🇷", dialCode: "+55"),
        CountryCode(name: "Mexico", code: "MX", flag: "🇲🇽", dialCode: "+52"),
        CountryCode(name: "Spain", code: "ES", flag: "🇪🇸", dialCode: "+34"),
        CountryCode(name: "Italy", code: "IT", flag: "🇮🇹", dialCode: "+39"),
        CountryCode(name: "Netherlands", code: "NL", flag: "🇳🇱", dialCode: "+31"),
        CountryCode(name: "Sweden", code: "SE", flag: "🇸🇪", dialCode: "+46"),
        CountryCode(name: "Norway", code: "NO", flag: "🇳🇴", dialCode: "+47"),
        CountryCode(name: "Denmark", code: "DK", flag: "🇩🇰", dialCode: "+45"),
        CountryCode(name: "Finland", code: "FI", flag: "🇫🇮", dialCode: "+358"),
        CountryCode(name: "Switzerland", code: "CH", flag: "🇨🇭", dialCode: "+41"),
        CountryCode(name: "Austria", code: "AT", flag: "🇦🇹", dialCode: "+43"),
        CountryCode(name: "Belgium", code: "BE", flag: "🇧🇪", dialCode: "+32"),
        CountryCode(name: "Ireland", code: "IE", flag: "🇮🇪", dialCode: "+353"),
        CountryCode(name: "New Zealand", code: "NZ", flag: "🇳🇿", dialCode: "+64"),
        CountryCode(name: "Singapore", code: "SG", flag: "🇸🇬", dialCode: "+65"),
        CountryCode(name: "Hong Kong", code: "HK", flag: "🇭🇰", dialCode: "+852"),
        CountryCode(name: "Taiwan", code: "TW", flag: "🇹🇼", dialCode: "+886"),
        CountryCode(name: "Thailand", code: "TH", flag: "🇹🇭", dialCode: "+66"),
        CountryCode(name: "Malaysia", code: "MY", flag: "🇲🇾", dialCode: "+60"),
        CountryCode(name: "Philippines", code: "PH", flag: "🇵🇭", dialCode: "+63"),
        CountryCode(name: "Indonesia", code: "ID", flag: "🇮🇩", dialCode: "+62"),
        CountryCode(name: "Vietnam", code: "VN", flag: "🇻🇳", dialCode: "+84"),
        CountryCode(name: "China", code: "CN", flag: "🇨🇳", dialCode: "+86"),
        CountryCode(name: "Russia", code: "RU", flag: "🇷🇺", dialCode: "+7"),
        CountryCode(name: "Turkey", code: "TR", flag: "🇹🇷", dialCode: "+90"),
        CountryCode(name: "Poland", code: "PL", flag: "🇵🇱", dialCode: "+48"),
        CountryCode(name: "Czech Republic", code: "CZ", flag: "🇨🇿", dialCode: "+420"),
        CountryCode(name: "Hungary", code: "HU", flag: "🇭🇺", dialCode: "+36"),
        CountryCode(name: "Romania", code: "RO", flag: "🇷🇴", dialCode: "+40"),
        CountryCode(name: "Bulgaria", code: "BG", flag: "🇧🇬", dialCode: "+359"),
        CountryCode(name: "Croatia", code: "HR", flag: "🇭🇷", dialCode: "+385"),
        CountryCode(name: "Slovenia", code: "SI", flag: "🇸🇮", dialCode: "+386"),
        CountryCode(name: "Slovakia", code: "SK", flag: "🇸🇰", dialCode: "+421"),
        CountryCode(name: "Estonia", code: "EE", flag: "🇪🇪", dialCode: "+372"),
        CountryCode(name: "Latvia", code: "LV", flag: "🇱🇻", dialCode: "+371"),
        CountryCode(name: "Lithuania", code: "LT", flag: "🇱🇹", dialCode: "+370"),
        CountryCode(name: "Luxembourg", code: "LU", flag: "🇱🇺", dialCode: "+352"),
        CountryCode(name: "Iceland", code: "IS", flag: "🇮🇸", dialCode: "+354"),
        CountryCode(name: "Malta", code: "MT", flag: "🇲🇹", dialCode: "+356"),
        CountryCode(name: "Cyprus", code: "CY", flag: "🇨🇾", dialCode: "+357"),
        CountryCode(name: "Greece", code: "GR", flag: "🇬🇷", dialCode: "+30"),
        CountryCode(name: "Portugal", code: "PT", flag: "🇵🇹", dialCode: "+351"),
        CountryCode(name: "Israel", code: "IL", flag: "🇮🇱", dialCode: "+972"),
        CountryCode(name: "UAE", code: "AE", flag: "🇦🇪", dialCode: "+971"),
        CountryCode(name: "Saudi Arabia", code: "SA", flag: "🇸🇦", dialCode: "+966"),
        CountryCode(name: "Qatar", code: "QA", flag: "🇶🇦", dialCode: "+974"),
        CountryCode(name: "Kuwait", code: "KW", flag: "🇰🇼", dialCode: "+965"),
        CountryCode(name: "Bahrain", code: "BH", flag: "🇧🇭", dialCode: "+973"),
        CountryCode(name: "Oman", code: "OM", flag: "🇴🇲", dialCode: "+968"),
        CountryCode(name: "Jordan", code: "JO", flag: "🇯🇴", dialCode: "+962"),
        CountryCode(name: "Lebanon", code: "LB", flag: "🇱🇧", dialCode: "+961"),
        CountryCode(name: "Egypt", code: "EG", flag: "🇪🇬", dialCode: "+20"),
        CountryCode(name: "South Africa", code: "ZA", flag: "🇿🇦", dialCode: "+27"),
        CountryCode(name: "Nigeria", code: "NG", flag: "🇳🇬", dialCode: "+234"),
        CountryCode(name: "Kenya", code: "KE", flag: "🇰🇪", dialCode: "+254"),
        CountryCode(name: "Ghana", code: "GH", flag: "🇬🇭", dialCode: "+233"),
        CountryCode(name: "Uganda", code: "UG", flag: "🇺🇬", dialCode: "+256"),
        CountryCode(name: "Tanzania", code: "TZ", flag: "🇹🇿", dialCode: "+255"),
        CountryCode(name: "Ethiopia", code: "ET", flag: "🇪🇹", dialCode: "+251"),
        CountryCode(name: "Morocco", code: "MA", flag: "🇲🇦", dialCode: "+212"),
        CountryCode(name: "Algeria", code: "DZ", flag: "🇩🇿", dialCode: "+213"),
        CountryCode(name: "Tunisia", code: "TN", flag: "🇹🇳", dialCode: "+216"),
        CountryCode(name: "Libya", code: "LY", flag: "🇱🇾", dialCode: "+218"),
        CountryCode(name: "Sudan", code: "SD", flag: "🇸🇩", dialCode: "+249"),
        CountryCode(name: "Chad", code: "TD", flag: "🇹🇩", dialCode: "+235"),
        CountryCode(name: "Niger", code: "NE", flag: "🇳🇪", dialCode: "+227"),
        CountryCode(name: "Mali", code: "ML", flag: "🇲🇱", dialCode: "+223"),
        CountryCode(name: "Burkina Faso", code: "BF", flag: "🇧🇫", dialCode: "+226"),
        CountryCode(name: "Senegal", code: "SN", flag: "🇸🇳", dialCode: "+221"),
        CountryCode(name: "Guinea", code: "GN", flag: "🇬🇳", dialCode: "+224"),
        CountryCode(name: "Sierra Leone", code: "SL", flag: "🇸🇱", dialCode: "+232"),
        CountryCode(name: "Liberia", code: "LR", flag: "🇱🇷", dialCode: "+231"),
        CountryCode(name: "Ivory Coast", code: "CI", flag: "🇨🇮", dialCode: "+225"),
        CountryCode(name: "Togo", code: "TG", flag: "🇹🇬", dialCode: "+228"),
        CountryCode(name: "Benin", code: "BJ", flag: "🇧🇯", dialCode: "+229"),
        CountryCode(name: "Cameroon", code: "CM", flag: "🇨🇲", dialCode: "+237"),
        CountryCode(name: "Central African Republic", code: "CF", flag: "🇨🇫", dialCode: "+236"),
        CountryCode(name: "Gabon", code: "GA", flag: "🇬🇦", dialCode: "+241"),
        CountryCode(name: "Congo", code: "CG", flag: "🇨🇬", dialCode: "+242"),
        CountryCode(name: "DR Congo", code: "CD", flag: "🇨🇩", dialCode: "+243"),
        CountryCode(name: "Angola", code: "AO", flag: "🇦🇴", dialCode: "+244"),
        CountryCode(name: "Zambia", code: "ZM", flag: "🇿🇲", dialCode: "+260"),
        CountryCode(name: "Zimbabwe", code: "ZW", flag: "🇿🇼", dialCode: "+263"),
        CountryCode(name: "Botswana", code: "BW", flag: "🇧🇼", dialCode: "+267"),
        CountryCode(name: "Namibia", code: "NA", flag: "🇳🇦", dialCode: "+264"),
        CountryCode(name: "Mozambique", code: "MZ", flag: "🇲🇿", dialCode: "+258"),
        CountryCode(name: "Madagascar", code: "MG", flag: "🇲🇬", dialCode: "+261"),
        CountryCode(name: "Mauritius", code: "MU", flag: "🇲🇺", dialCode: "+230"),
        CountryCode(name: "Seychelles", code: "SC", flag: "🇸🇨", dialCode: "+248"),
        CountryCode(name: "Comoros", code: "KM", flag: "🇰🇲", dialCode: "+269"),
        CountryCode(name: "Djibouti", code: "DJ", flag: "🇩🇯", dialCode: "+253"),
        CountryCode(name: "Somalia", code: "SO", flag: "🇸🇴", dialCode: "+252"),
        CountryCode(name: "Eritrea", code: "ER", flag: "🇪🇷", dialCode: "+291"),
        CountryCode(name: "Yemen", code: "YE", flag: "🇾🇪", dialCode: "+967"),
        CountryCode(name: "Syria", code: "SY", flag: "🇸🇾", dialCode: "+963"),
        CountryCode(name: "Iraq", code: "IQ", flag: "🇮🇶", dialCode: "+964"),
        CountryCode(name: "Iran", code: "IR", flag: "🇮🇷", dialCode: "+98"),
        CountryCode(name: "Afghanistan", code: "AF", flag: "🇦🇫", dialCode: "+93"),
        CountryCode(name: "Pakistan", code: "PK", flag: "🇵🇰", dialCode: "+92"),
        CountryCode(name: "Bangladesh", code: "BD", flag: "🇧🇩", dialCode: "+880"),
        CountryCode(name: "Sri Lanka", code: "LK", flag: "🇱🇰", dialCode: "+94"),
        CountryCode(name: "Nepal", code: "NP", flag: "🇳🇵", dialCode: "+977"),
        CountryCode(name: "Bhutan", code: "BT", flag: "🇧🇹", dialCode: "+975"),
        CountryCode(name: "Myanmar", code: "MM", flag: "🇲🇲", dialCode: "+95"),
        CountryCode(name: "Laos", code: "LA", flag: "🇱🇦", dialCode: "+856"),
        CountryCode(name: "Cambodia", code: "KH", flag: "🇰🇭", dialCode: "+855"),
        CountryCode(name: "Brunei", code: "BN", flag: "🇧🇳", dialCode: "+673"),
        CountryCode(name: "East Timor", code: "TL", flag: "🇹🇱", dialCode: "+670"),
        CountryCode(name: "Papua New Guinea", code: "PG", flag: "🇵🇬", dialCode: "+675"),
        CountryCode(name: "Fiji", code: "FJ", flag: "🇫🇯", dialCode: "+679"),
        CountryCode(name: "Vanuatu", code: "VU", flag: "🇻🇺", dialCode: "+678"),
        CountryCode(name: "New Caledonia", code: "NC", flag: "🇳🇨", dialCode: "+687"),
        CountryCode(name: "Solomon Islands", code: "SB", flag: "🇸🇧", dialCode: "+677"),
        CountryCode(name: "Samoa", code: "WS", flag: "🇼🇸", dialCode: "+685"),
        CountryCode(name: "Tonga", code: "TO", flag: "🇹🇴", dialCode: "+676"),
        CountryCode(name: "Kiribati", code: "KI", flag: "🇰🇮", dialCode: "+686"),
        CountryCode(name: "Tuvalu", code: "TV", flag: "🇹🇻", dialCode: "+688"),
        CountryCode(name: "Nauru", code: "NR", flag: "🇳🇷", dialCode: "+674"),
        CountryCode(name: "Palau", code: "PW", flag: "🇵🇼", dialCode: "+680"),
        CountryCode(name: "Marshall Islands", code: "MH", flag: "🇲🇭", dialCode: "+692"),
        CountryCode(name: "Micronesia", code: "FM", flag: "🇫🇲", dialCode: "+691"),
        CountryCode(name: "Guam", code: "GU", flag: "🇬🇺", dialCode: "+1"),
        CountryCode(name: "Northern Mariana Islands", code: "MP", flag: "🇲🇵", dialCode: "+1"),
        CountryCode(name: "American Samoa", code: "AS", flag: "🇦🇸", dialCode: "+1"),
        CountryCode(name: "Puerto Rico", code: "PR", flag: "🇵🇷", dialCode: "+1"),
        CountryCode(name: "U.S. Virgin Islands", code: "VI", flag: "🇻🇮", dialCode: "+1"),
        CountryCode(name: "Greenland", code: "GL", flag: "🇬🇱", dialCode: "+299"),
        CountryCode(name: "Faroe Islands", code: "FO", flag: "🇫🇴", dialCode: "+298"),
        CountryCode(name: "Åland Islands", code: "AX", flag: "🇦🇽", dialCode: "+358"),
        CountryCode(name: "Isle of Man", code: "IM", flag: "🇮🇲", dialCode: "+44"),
        CountryCode(name: "Jersey", code: "JE", flag: "🇯🇪", dialCode: "+44"),
        CountryCode(name: "Guernsey", code: "GG", flag: "🇬🇬", dialCode: "+44"),
        CountryCode(name: "Gibraltar", code: "GI", flag: "🇬🇮", dialCode: "+350"),
        CountryCode(name: "Monaco", code: "MC", flag: "🇲🇨", dialCode: "+377"),
        CountryCode(name: "Liechtenstein", code: "LI", flag: "🇱🇮", dialCode: "+423"),
        CountryCode(name: "San Marino", code: "SM", flag: "🇸🇲", dialCode: "+378"),
        CountryCode(name: "Vatican City", code: "VA", flag: "🇻🇦", dialCode: "+379"),
        CountryCode(name: "Andorra", code: "AD", flag: "🇦🇩", dialCode: "+376"),
        CountryCode(name: "Luxembourg", code: "LU", flag: "🇱🇺", dialCode: "+352"),
        CountryCode(name: "Moldova", code: "MD", flag: "🇲🇩", dialCode: "+373"),
        CountryCode(name: "Belarus", code: "BY", flag: "🇧🇾", dialCode: "+375"),
        CountryCode(name: "Ukraine", code: "UA", flag: "🇺🇦", dialCode: "+380"),
        CountryCode(name: "Georgia", code: "GE", flag: "🇬🇪", dialCode: "+995"),
        CountryCode(name: "Armenia", code: "AM", flag: "🇦🇲", dialCode: "+374"),
        CountryCode(name: "Azerbaijan", code: "AZ", flag: "🇦🇿", dialCode: "+994"),
        CountryCode(name: "Kazakhstan", code: "KZ", flag: "🇰🇿", dialCode: "+7"),
        CountryCode(name: "Uzbekistan", code: "UZ", flag: "🇺🇿", dialCode: "+998"),
        CountryCode(name: "Turkmenistan", code: "TM", flag: "🇹🇲", dialCode: "+993"),
        CountryCode(name: "Tajikistan", code: "TJ", flag: "🇹🇯", dialCode: "+992"),
        CountryCode(name: "Kyrgyzstan", code: "KG", flag: "🇰🇬", dialCode: "+996"),
        CountryCode(name: "Mongolia", code: "MN", flag: "🇲🇳", dialCode: "+976"),
        CountryCode(name: "North Korea", code: "KP", flag: "🇰🇵", dialCode: "+850"),
        CountryCode(name: "Maldives", code: "MV", flag: "🇲🇻", dialCode: "+960"),
        CountryCode(name: "Kyrgyzstan", code: "KG", flag: "🇰🇬", dialCode: "+996"),
        CountryCode(name: "Tajikistan", code: "TJ", flag: "🇹🇯", dialCode: "+992"),
        CountryCode(name: "Turkmenistan", code: "TM", flag: "🇹🇲", dialCode: "+993"),
        CountryCode(name: "Uzbekistan", code: "UZ", flag: "🇺🇿", dialCode: "+998"),
        CountryCode(name: "Kazakhstan", code: "KZ", flag: "🇰🇿", dialCode: "+7"),
        CountryCode(name: "Azerbaijan", code: "AZ", flag: "🇦🇿", dialCode: "+994"),
        CountryCode(name: "Armenia", code: "AM", flag: "🇦🇲", dialCode: "+374"),
        CountryCode(name: "Georgia", code: "GE", flag: "🇬🇪", dialCode: "+995"),
        CountryCode(name: "Ukraine", code: "UA", flag: "🇺🇦", dialCode: "+380"),
        CountryCode(name: "Belarus", code: "BY", flag: "🇧🇾", dialCode: "+375"),
        CountryCode(name: "Moldova", code: "MD", flag: "🇲🇩", dialCode: "+373"),
        CountryCode(name: "Luxembourg", code: "LU", flag: "🇱🇺", dialCode: "+352"),
        CountryCode(name: "Andorra", code: "AD", flag: "🇦🇩", dialCode: "+376"),
        CountryCode(name: "Vatican City", code: "VA", flag: "🇻🇦", dialCode: "+379"),
        CountryCode(name: "San Marino", code: "SM", flag: "🇸🇲", dialCode: "+378"),
        CountryCode(name: "Liechtenstein", code: "LI", flag: "🇱🇮", dialCode: "+423"),
        CountryCode(name: "Monaco", code: "MC", flag: "🇲🇨", dialCode: "+377"),
        CountryCode(name: "Gibraltar", code: "GI", flag: "🇬🇮", dialCode: "+350"),
        CountryCode(name: "Guernsey", code: "GG", flag: "🇬🇬", dialCode: "+44"),
        CountryCode(name: "Jersey", code: "JE", flag: "🇯🇪", dialCode: "+44"),
        CountryCode(name: "Isle of Man", code: "IM", flag: "🇮🇲", dialCode: "+44"),
        CountryCode(name: "Åland Islands", code: "AX", flag: "🇦🇽", dialCode: "+358"),
        CountryCode(name: "Faroe Islands", code: "FO", flag: "🇫🇴", dialCode: "+298"),
        CountryCode(name: "Greenland", code: "GL", flag: "🇬🇱", dialCode: "+299"),
        CountryCode(name: "U.S. Virgin Islands", code: "VI", flag: "🇻🇮", dialCode: "+1"),
        CountryCode(name: "Puerto Rico", code: "PR", flag: "🇵🇷", dialCode: "+1"),
        CountryCode(name: "American Samoa", code: "AS", flag: "🇦🇸", dialCode: "+1"),
        CountryCode(name: "Northern Mariana Islands", code: "MP", flag: "🇲🇵", dialCode: "+1"),
        CountryCode(name: "Guam", code: "GU", flag: "🇬🇺", dialCode: "+1"),
        CountryCode(name: "Micronesia", code: "FM", flag: "🇫🇲", dialCode: "+691"),
        CountryCode(name: "Marshall Islands", code: "MH", flag: "🇲🇭", dialCode: "+692"),
        CountryCode(name: "Palau", code: "PW", flag: "🇵🇼", dialCode: "+680"),
        CountryCode(name: "Nauru", code: "NR", flag: "🇳🇷", dialCode: "+674"),
        CountryCode(name: "Tuvalu", code: "TV", flag: "🇹🇻", dialCode: "+688"),
        CountryCode(name: "Kiribati", code: "KI", flag: "🇰🇮", dialCode: "+686"),
        CountryCode(name: "Tonga", code: "TO", flag: "🇹🇴", dialCode: "+676"),
        CountryCode(name: "Samoa", code: "WS", flag: "🇼🇸", dialCode: "+685"),
        CountryCode(name: "Solomon Islands", code: "SB", flag: "🇸🇧", dialCode: "+677"),
        CountryCode(name: "New Caledonia", code: "NC", flag: "🇳🇨", dialCode: "+687"),
        CountryCode(name: "Vanuatu", code: "VU", flag: "🇻🇺", dialCode: "+678"),
        CountryCode(name: "Fiji", code: "FJ", flag: "🇫🇯", dialCode: "+679"),
        CountryCode(name: "Papua New Guinea", code: "PG", flag: "🇵🇬", dialCode: "+675"),
        CountryCode(name: "East Timor", code: "TL", flag: "🇹🇱", dialCode: "+670"),
        CountryCode(name: "Brunei", code: "BN", flag: "🇧🇳", dialCode: "+673"),
        CountryCode(name: "Cambodia", code: "KH", flag: "🇰🇭", dialCode: "+855"),
        CountryCode(name: "Laos", code: "LA", flag: "🇱🇦", dialCode: "+856"),
        CountryCode(name: "Myanmar", code: "MM", flag: "🇲🇲", dialCode: "+95"),
        CountryCode(name: "Bhutan", code: "BT", flag: "🇧🇹", dialCode: "+975"),
        CountryCode(name: "Nepal", code: "NP", flag: "🇳🇵", dialCode: "+977"),
        CountryCode(name: "Sri Lanka", code: "LK", flag: "🇱🇰", dialCode: "+94"),
        CountryCode(name: "Bangladesh", code: "BD", flag: "🇧🇩", dialCode: "+880"),
        CountryCode(name: "Pakistan", code: "PK", flag: "🇵🇰", dialCode: "+92"),
        CountryCode(name: "Afghanistan", code: "AF", flag: "🇦🇫", dialCode: "+93"),
        CountryCode(name: "Iran", code: "IR", flag: "🇮🇷", dialCode: "+98"),
        CountryCode(name: "Iraq", code: "IQ", flag: "🇮🇶", dialCode: "+964"),
        CountryCode(name: "Syria", code: "SY", flag: "🇸🇾", dialCode: "+963"),
        CountryCode(name: "Yemen", code: "YE", flag: "🇾🇪", dialCode: "+967"),
        CountryCode(name: "Eritrea", code: "ER", flag: "🇪🇷", dialCode: "+291"),
        CountryCode(name: "Somalia", code: "SO", flag: "🇸🇴", dialCode: "+252"),
        CountryCode(name: "Djibouti", code: "DJ", flag: "🇩🇯", dialCode: "+253"),
        CountryCode(name: "Comoros", code: "KM", flag: "🇰🇲", dialCode: "+269"),
        CountryCode(name: "Seychelles", code: "SC", flag: "🇸🇨", dialCode: "+248"),
        CountryCode(name: "Mauritius", code: "MU", flag: "🇲🇺", dialCode: "+230"),
        CountryCode(name: "Madagascar", code: "MG", flag: "🇲🇬", dialCode: "+261"),
        CountryCode(name: "Mozambique", code: "MZ", flag: "🇲🇿", dialCode: "+258"),
        CountryCode(name: "Namibia", code: "NA", flag: "🇳🇦", dialCode: "+264"),
        CountryCode(name: "Botswana", code: "BW", flag: "🇧🇼", dialCode: "+267"),
        CountryCode(name: "Zimbabwe", code: "ZW", flag: "🇿🇼", dialCode: "+263"),
        CountryCode(name: "Zambia", code: "ZM", flag: "🇿🇲", dialCode: "+260"),
        CountryCode(name: "Angola", code: "AO", flag: "🇦🇴", dialCode: "+244"),
        CountryCode(name: "DR Congo", code: "CD", flag: "🇨🇩", dialCode: "+243"),
        CountryCode(name: "Congo", code: "CG", flag: "🇨🇬", dialCode: "+242"),
        CountryCode(name: "Gabon", code: "GA", flag: "🇬🇦", dialCode: "+241"),
        CountryCode(name: "Central African Republic", code: "CF", flag: "🇨🇫", dialCode: "+236"),
        CountryCode(name: "Cameroon", code: "CM", flag: "🇨🇲", dialCode: "+237"),
        CountryCode(name: "Benin", code: "BJ", flag: "🇧🇯", dialCode: "+229"),
        CountryCode(name: "Togo", code: "TG", flag: "🇹🇬", dialCode: "+228"),
        CountryCode(name: "Ivory Coast", code: "CI", flag: "🇨🇮", dialCode: "+225"),
        CountryCode(name: "Liberia", code: "LR", flag: "🇱🇷", dialCode: "+231"),
        CountryCode(name: "Sierra Leone", code: "SL", flag: "🇸🇱", dialCode: "+232"),
        CountryCode(name: "Guinea", code: "GN", flag: "🇬🇳", dialCode: "+224"),
        CountryCode(name: "Senegal", code: "SN", flag: "🇸🇳", dialCode: "+221"),
        CountryCode(name: "Burkina Faso", code: "BF", flag: "🇧🇫", dialCode: "+226"),
        CountryCode(name: "Mali", code: "ML", flag: "🇲🇱", dialCode: "+223"),
        CountryCode(name: "Niger", code: "NE", flag: "🇳🇪", dialCode: "+227"),
        CountryCode(name: "Chad", code: "TD", flag: "🇹🇩", dialCode: "+235"),
        CountryCode(name: "Sudan", code: "SD", flag: "🇸🇩", dialCode: "+249"),
        CountryCode(name: "Libya", code: "LY", flag: "🇱🇾", dialCode: "+218"),
        CountryCode(name: "Tunisia", code: "TN", flag: "🇹🇳", dialCode: "+216"),
        CountryCode(name: "Algeria", code: "DZ", flag: "🇩🇿", dialCode: "+213"),
        CountryCode(name: "Morocco", code: "MA", flag: "🇲🇦", dialCode: "+212"),
        CountryCode(name: "Ethiopia", code: "ET", flag: "🇪🇹", dialCode: "+251"),
        CountryCode(name: "Tanzania", code: "TZ", flag: "🇹🇿", dialCode: "+255"),
        CountryCode(name: "Uganda", code: "UG", flag: "🇺🇬", dialCode: "+256"),
        CountryCode(name: "Ghana", code: "GH", flag: "🇬🇭", dialCode: "+233"),
        CountryCode(name: "Kenya", code: "KE", flag: "🇰🇪", dialCode: "+254"),
        CountryCode(name: "Nigeria", code: "NG", flag: "🇳🇬", dialCode: "+234"),
        CountryCode(name: "South Africa", code: "ZA", flag: "🇿🇦", dialCode: "+27"),
        CountryCode(name: "Egypt", code: "EG", flag: "🇪🇬", dialCode: "+20"),
        CountryCode(name: "Lebanon", code: "LB", flag: "🇱🇧", dialCode: "+961"),
        CountryCode(name: "Jordan", code: "JO", flag: "🇯🇴", dialCode: "+962"),
        CountryCode(name: "Oman", code: "OM", flag: "🇴🇲", dialCode: "+968"),
        CountryCode(name: "Bahrain", code: "BH", flag: "🇧🇭", dialCode: "+973"),
        CountryCode(name: "Kuwait", code: "KW", flag: "🇰🇼", dialCode: "+965"),
        CountryCode(name: "Qatar", code: "QA", flag: "🇶🇦", dialCode: "+974"),
        CountryCode(name: "Saudi Arabia", code: "SA", flag: "🇸🇦", dialCode: "+966"),
        CountryCode(name: "UAE", code: "AE", flag: "🇦🇪", dialCode: "+971"),
        CountryCode(name: "Israel", code: "IL", flag: "🇮🇱", dialCode: "+972"),
        CountryCode(name: "Portugal", code: "PT", flag: "🇵🇹", dialCode: "+351"),
        CountryCode(name: "Greece", code: "GR", flag: "🇬🇷", dialCode: "+30"),
        CountryCode(name: "Cyprus", code: "CY", flag: "🇨🇾", dialCode: "+357"),
        CountryCode(name: "Malta", code: "MT", flag: "🇲🇹", dialCode: "+356"),
        CountryCode(name: "Iceland", code: "IS", flag: "🇮🇸", dialCode: "+354"),
        CountryCode(name: "Luxembourg", code: "LU", flag: "🇱🇺", dialCode: "+352"),
        CountryCode(name: "Lithuania", code: "LT", flag: "🇱🇹", dialCode: "+370"),
        CountryCode(name: "Latvia", code: "LV", flag: "🇱🇻", dialCode: "+371"),
        CountryCode(name: "Estonia", code: "EE", flag: "🇪🇪", dialCode: "+372"),
        CountryCode(name: "Slovakia", code: "SK", flag: "🇸🇰", dialCode: "+421"),
        CountryCode(name: "Slovenia", code: "SI", flag: "🇸🇮", dialCode: "+386"),
        CountryCode(name: "Croatia", code: "HR", flag: "🇭🇷", dialCode: "+385"),
        CountryCode(name: "Bulgaria", code: "BG", flag: "🇧🇬", dialCode: "+359"),
        CountryCode(name: "Romania", code: "RO", flag: "🇷🇴", dialCode: "+40"),
        CountryCode(name: "Hungary", code: "HU", flag: "🇭🇺", dialCode: "+36"),
        CountryCode(name: "Czech Republic", code: "CZ", flag: "🇨🇿", dialCode: "+420"),
        CountryCode(name: "Poland", code: "PL", flag: "🇵🇱", dialCode: "+48"),
        CountryCode(name: "Turkey", code: "TR", flag: "🇹🇷", dialCode: "+90"),
        CountryCode(name: "Russia", code: "RU", flag: "🇷🇺", dialCode: "+7"),
        CountryCode(name: "China", code: "CN", flag: "🇨🇳", dialCode: "+86"),
        CountryCode(name: "Vietnam", code: "VN", flag: "🇻🇳", dialCode: "+84"),
        CountryCode(name: "Indonesia", code: "ID", flag: "🇮🇩", dialCode: "+62"),
        CountryCode(name: "Philippines", code: "PH", flag: "🇵🇭", dialCode: "+63"),
        CountryCode(name: "Malaysia", code: "MY", flag: "🇲🇾", dialCode: "+60"),
        CountryCode(name: "Thailand", code: "TH", flag: "🇹🇭", dialCode: "+66"),
        CountryCode(name: "Taiwan", code: "TW", flag: "🇹🇼", dialCode: "+886"),
        CountryCode(name: "Hong Kong", code: "HK", flag: "🇭🇰", dialCode: "+852"),
        CountryCode(name: "Singapore", code: "SG", flag: "🇸🇬", dialCode: "+65"),
        CountryCode(name: "New Zealand", code: "NZ", flag: "🇳🇿", dialCode: "+64"),
        CountryCode(name: "Ireland", code: "IE", flag: "🇮🇪", dialCode: "+353"),
        CountryCode(name: "Belgium", code: "BE", flag: "🇧🇪", dialCode: "+32"),
        CountryCode(name: "Austria", code: "AT", flag: "🇦🇹", dialCode: "+43"),
        CountryCode(name: "Switzerland", code: "CH", flag: "🇨🇭", dialCode: "+41"),
        CountryCode(name: "Finland", code: "FI", flag: "🇫🇮", dialCode: "+358"),
        CountryCode(name: "Denmark", code: "DK", flag: "🇩🇰", dialCode: "+45"),
        CountryCode(name: "Norway", code: "NO", flag: "🇳🇴", dialCode: "+47"),
        CountryCode(name: "Sweden", code: "SE", flag: "🇸🇪", dialCode: "+46"),
        CountryCode(name: "Netherlands", code: "NL", flag: "🇳🇱", dialCode: "+31"),
        CountryCode(name: "Italy", code: "IT", flag: "🇮🇹", dialCode: "+39"),
        CountryCode(name: "Spain", code: "ES", flag: "🇪🇸", dialCode: "+34"),
        CountryCode(name: "Mexico", code: "MX", flag: "🇲🇽", dialCode: "+52"),
        CountryCode(name: "Brazil", code: "BR", flag: "🇧🇷", dialCode: "+55"),
        CountryCode(name: "South Korea", code: "KR", flag: "🇰🇷", dialCode: "+82"),
        CountryCode(name: "Japan", code: "JP", flag: "🇯🇵", dialCode: "+81"),
        CountryCode(name: "France", code: "FR", flag: "🇫🇷", dialCode: "+33"),
        CountryCode(name: "Germany", code: "DE", flag: "🇩🇪", dialCode: "+49"),
        CountryCode(name: "Australia", code: "AU", flag: "🇦🇺", dialCode: "+61"),
        CountryCode(name: "India", code: "IN", flag: "🇮🇳", dialCode: "+91"),
        CountryCode(name: "United Kingdom", code: "GB", flag: "🇬🇧", dialCode: "+44"),
        CountryCode(name: "Canada", code: "CA", flag: "🇨🇦", dialCode: "+1"),
        CountryCode(name: "United States", code: "US", flag: "🇺🇸", dialCode: "+1")
    ]
    
    static func findCountryCode(for dialCode: String) -> CountryCode? {
        return allCountries.first { $0.dialCode == dialCode }
    }
}

// MARK: - Phone Validation Functions
func isValidPhoneNumber(_ phone: String) -> Bool {
    // Remove all non-digit characters for validation
    let digitsOnly = phone.filter { $0.isNumber }
    
    // Basic validation: 7-15 digits
    guard digitsOnly.count >= 7 && digitsOnly.count <= 15 else { return false }
    
    // Check for common patterns
    let patterns = [
        "^\\+?[1-9]\\d{1,14}$", // International format
        "^[1-9]\\d{6,14}$", // National format
        "^\\+?1\\d{10}$", // US/Canada format
        "^\\+?44\\d{10}$", // UK format
        "^\\+?91\\d{10}$", // India format
        "^\\+?61\\d{9}$", // Australia format
        "^\\+?49\\d{10,11}$", // Germany format
        "^\\+?33\\d{9}$", // France format
        "^\\+?81\\d{9,10}$", // Japan format
        "^\\+?82\\d{9,10}$" // South Korea format
    ]
    
    return patterns.contains { pattern in
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: phone.count)
        return regex?.firstMatch(in: phone, range: range) != nil
    }
}

func formatPhoneNumber(_ phone: String, countryCode: CountryCode) -> String {
    let digitsOnly = phone.filter { $0.isNumber }
    
    // If it already starts with the country code, return as is
    if phone.hasPrefix(countryCode.dialCode) {
        return phone
    }
    
    // Add country code if not present
    return countryCode.dialCode + digitsOnly
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Custom large, centered title
                    HStack {
                        Spacer()
                        Text("Profile")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 8)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        Spacer()
                    }
                    // Profile header
                    ProfileHeaderView(isDark: isDark)
                    
                    // Quick actions
                    QuickActionsView(isDark: isDark)
                        .environmentObject(appearanceManager)
                        .environmentObject(authManager)
                    
                    // Settings sections
                    SettingsSectionView(isDark: isDark)
                    
                    // Subscription section
                    SubscriptionSectionView(isDark: isDark)
                        .environmentObject(appearanceManager)
                        .environmentObject(authManager)
                    
                    // Support section
                    SupportSectionView(isDark: isDark)
                    
                    // Sign out button
                    SignOutButton(isDark: isDark)
                    
                    Spacer()
                }
                .padding()
            }
            .refreshable {
                // Pull-to-refresh functionality
                print("🔄 ProfileView: Pull-to-refresh triggered")
                await authManager.forceRefreshUserProfile()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
        .id(appearanceManager.colorSchemePreference)
    }
    
    private var isDark: Bool { appearanceManager.colorSchemePreference == "dark" || (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark) }
}

struct ProfileHeaderView: View {
    var isDark: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var showingImagePicker = false
    @State private var profileImage: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State private var showSaveConfirmation = false
    
    private var profileImageKey: String {
        "profile_image_\(authManager.userProfile?.id.lowercased() ?? "unknown")"
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            ProfileImageView(
                profileImage: $profileImage,
                showingImagePicker: $showingImagePicker,
                inputImage: $inputImage,
                showSaveConfirmation: $showSaveConfirmation,
                profileImageKey: profileImageKey,
                onLoadImage: loadImage,
                onLoadSavedImage: loadSavedProfileImage
            )
            
            ProfileInfoView(
                isDark: isDark,
                authManager: authManager
            )
            .environmentObject(userTierManager)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            isDark
                ? AnyView(NuraColors.cardDark)
                : AnyView(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
    
    private func loadSavedProfileImage() {
        guard let userProfile = authManager.userProfile else {
            print("❌ No user profile available for loading image")
            return
        }
        
        print("🔄 Loading profile image for user: \(userProfile.id)")
        print("🔄 Profile image key: \(profileImageKey)")
        
        // First try the standardized lowercase key
        if let imageData = UserDefaults.standard.data(forKey: profileImageKey),
           let uiImage = UIImage(data: imageData) {
            profileImage = Image(uiImage: uiImage)
            print("✅ Profile image loaded for user: \(userProfile.id)")
        } else {
            print("❌ No profile image found for key: \(profileImageKey)")
            
            // Try to find any saved profile image for this user with different case variations
            let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
            let profileImageKeys = allKeys.filter { $0.hasPrefix("profile_image_") }
            print("🔍 Available profile image keys: \(profileImageKeys)")
            
            // Look for existing image with different case variations
            let userId = userProfile.id
            let possibleKeys = [
                "profile_image_\(userId)",
                "profile_image_\(userId.uppercased())",
                "profile_image_\(userId.lowercased())"
            ]
            
            for key in possibleKeys {
                if let imageData = UserDefaults.standard.data(forKey: key),
                   let uiImage = UIImage(data: imageData) {
                    // Found existing image, migrate it to standardized key
                    UserDefaults.standard.set(imageData, forKey: profileImageKey)
                    profileImage = Image(uiImage: uiImage)
                    print("✅ Migrated profile image from key '\(key)' to '\(profileImageKey)'")
                    print("✅ Profile image loaded for user: \(userProfile.id)")
                    return
                }
            }
            
            // Clear any old profile image to ensure clean state
            profileImage = nil
            print("ℹ️ No profile image found for current user. Profile image cleared.")
        }
    }
}

// MARK: - Profile Image View Component
struct ProfileImageView: View {
    @Binding var profileImage: Image?
    @Binding var showingImagePicker: Bool
    @Binding var inputImage: UIImage?
    @Binding var showSaveConfirmation: Bool
    let profileImageKey: String
    let onLoadImage: () -> Void
    let onLoadSavedImage: () -> Void
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        ZStack(alignment: .center) {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 4)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 100, height: 100)
        .onAppear {
            onLoadSavedImage()
        }
        .onChange(of: authManager.userProfile?.id) { oldValue, newValue in
            print("🔄 ProfileImageView: userProfile.id changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
            if newValue != nil {
                onLoadSavedImage()
            }
        }
        .onChange(of: authManager.userProfile?.name) { oldValue, newValue in
            print("🔄 ProfileImageView: userProfile.name changed from '\(oldValue ?? "nil")' to '\(newValue ?? "nil")'")
        }
    }
}

// MARK: - Save Confirmation Overlay Component
struct SaveConfirmationOverlay: View {
    @Binding var showSaveConfirmation: Bool
    
    var body: some View {
        Group {
            if showSaveConfirmation {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Profile photo saved!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSaveConfirmation)
    }
}

// MARK: - Profile Info View Component
struct ProfileInfoView: View {
    let isDark: Bool
    let authManager: AuthenticationManager
    @EnvironmentObject var userTierManager: UserTierManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
            
            ProfileNameView(authManager: authManager)
            
            Text(authManager.userProfile?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("Member since \(formatDate(Date()))")
                .font(.caption)
                .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
            
            if userTierManager.tier == .pro {
                Text("Nura Pro Member")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
            } else if userTierManager.tier == .proUnlimited {
                Text("Nura Pro Unlimited")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.1)) // Red-orange for special feeling
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Profile Name View Component
struct ProfileNameView: View {
    let authManager: AuthenticationManager
    
    var body: some View {
        let displayName = authManager.getDisplayName()
        
        HStack {
            Text(displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Debug indicator for empty name (only show if both temp and profile names are empty)
            if authManager.tempUserName?.isEmpty ?? true && (authManager.userProfile?.name.isEmpty ?? true) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
        .onAppear {
            print("🔄 ProfileNameView displaying name: '\(displayName)'")
            print("🔄 ProfileNameView tempUserName: '\(authManager.tempUserName ?? "nil")'")
            print("🔄 ProfileNameView userProfile: \(authManager.userProfile?.id ?? "nil")")
            print("🔄 ProfileNameView userProfile name: '\(authManager.userProfile?.name ?? "nil")'")
            print("🔄 ProfileNameView userProfile exists: \(authManager.userProfile != nil)")
            if let profile = authManager.userProfile {
                print("🔄 ProfileNameView full profile: id=\(profile.id), email=\(profile.email), name='\(profile.name)'")
                
                // Debug: If name is empty, check what's actually in the database
                if profile.name.isEmpty && (authManager.tempUserName?.isEmpty ?? true) {
                    print("⚠️ DEBUG: Empty name detected, checking database content...")
                    Task {
                        await authManager.debugCheckDatabaseContent(userId: profile.id)
                    }
                }
            }
        }
        .onTapGesture {
            // Debug: Force refresh profile when name is tapped
            print("🔄 ProfileNameView tapped - forcing refresh")
            Task {
                await authManager.forceRefreshUserProfile()
            }
        }
    }
}

struct QuickActionsView: View {
    var isDark: Bool
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var showRoutine = false
    @State private var showAppPreferences = false
    @State private var showSkinDiary = false
    @State private var showNuraProSheet = false
    @State private var animateUnlockButton = false
    @State private var showViewProgress = false
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Nura Pro Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.bottom, 2)
            ZStack {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    QuickActionCard(
                        title: "View Progress",
                        subtitle: "Track results",
                        icon: "chart.line.uptrend.xyaxis",
                        color: NuraColors.success
                    ) {
                        showViewProgress = true
                    }
                    QuickActionCard(
                        title: "Routine",
                        subtitle: "Daily steps",
                        icon: "list.bullet",
                        color: NuraColors.secondary
                    ) {
                        showRoutine = true
                    }
                    QuickActionCard(
                        title: "App Preferences",
                        subtitle: "Theme & Mode",
                        icon: "gearshape.fill",
                        color: NuraColors.textSecondary
                    ) {
                        showAppPreferences = true
                    }
                    QuickActionCard(
                        title: "Skin Diary",
                        subtitle: "Log changes",
                        icon: "book.closed.fill",
                        color: NuraColors.secondary
                    ) {
                        showSkinDiary = true
                    }
                }
                if !userTierManager.isPremium {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDark ? Color(red: 0.13, green: 0.12, blue: 0.11, opacity: 0.38) : Color(red: 0.65, green: 0.60, blue: 0.55, opacity: 0.28))
                        .overlay(
                            VStack(spacing: 24) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(isDark ? NuraColors.primary : NuraColors.primary)
                                    .padding(.top, 8)
                                Button(action: { showNuraProSheet = true }) {
                                    Text("Unlock Premium")
                                        .fontWeight(.semibold)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 36)
                                        .background(isDark ? NuraColors.primaryDark : NuraColors.primary)
                                        .foregroundColor(.white)
                                        .cornerRadius(22)
                                        .shadow(color: (isDark ? NuraColors.primaryDark : NuraColors.primary).opacity(0.15), radius: 6, x: 0, y: 2)
                                }
                            }
                            .padding(.vertical, 32)
                            .frame(maxWidth: 320)
                            .scaleEffect(animateUnlockButton ? 1.18 : 1.0, anchor: .center)
                            .animation(.spring(response: 0.38, dampingFraction: 0.55), value: animateUnlockButton)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            animateUnlockButton = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                                animateUnlockButton = false
                            }
                        }
                        .sheet(isPresented: $showNuraProSheet) {
                            NuraProView()
                        }
                }
            }
            // Add a smaller, soft, centered info pill below the grid
            HStack {
                Spacer()
                Text("More stuff incoming…")
                    .font(.footnote)
                    .foregroundColor(Color.primary.opacity(0.55))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 18)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                Spacer()
            }
            .padding(.top, 8)
        .sheet(isPresented: $showAppPreferences) {
            AppPreferencesPageView(isPresented: $showAppPreferences)
                .environmentObject(appearanceManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showSkinDiary) {
            SkinDiaryView()
        }
        }
        .padding()
        .background(
            isDark
                ? AnyView(NuraColors.cardDark)
                : AnyView(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showRoutine) {
            RoutineView()
        }
        .sheet(isPresented: $showViewProgress) {
            ViewProgressView()
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSectionView: View {
    var isDark: Bool
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSettings = false
    @State private var showingPersonalInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Personal Information",
                    subtitle: "Update your profile",
                    icon: "person.circle.fill",
                    color: NuraColors.secondary
                ) {
                    showingPersonalInfo = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Notifications",
                    subtitle: "Manage alerts",
                    icon: "bell.fill",
                    color: NuraColors.secondary
                ) {
                    showingSettings = false
                    showingPersonalInfo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(
                                UIHostingController(rootView: LocalNotificationsView()), animated: true, completion: nil)
                        }
                    }
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Privacy & Security",
                    subtitle: "Data and privacy settings",
                    icon: "lock.fill",
                    color: NuraColors.success
                ) {
                    showingSettings = false
                    showingPersonalInfo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            let privacyView = PrivacyAndSecurityView()
                                .environmentObject(authManager)
                            window.rootViewController?.present(
                                UIHostingController(rootView: privacyView), animated: true, completion: nil)
                        }
                    }
                }
                
                Divider()
                    .padding(.leading, 50)
                
            }
            .background(
                isDark
                    ? AnyView(NuraColors.cardDark)
                    : AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPersonalInfo) {
            PersonalInformationView()
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

struct SubscriptionSectionView: View {
    var isDark: Bool
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSubscription = false
    @State private var showingAppPreferences = false
    @State private var showingPaymentMethods = false
    @State private var showingBillingHistory = false
    @State private var showingNuraPro = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Subscription")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Compare Plans",
                    subtitle: "View subscription options",
                    icon: "crown.fill",
                    color: NuraColors.secondary
                ) {
                    showingNuraPro = true
                }
                .sheet(isPresented: $showingNuraPro) {
                    NuraProView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Payment Methods",
                    subtitle: "Manage billing",
                    icon: "creditcard.fill",
                    color: NuraColors.primary
                ) {
                    showingPaymentMethods = true
                }
                .sheet(isPresented: $showingPaymentMethods) {
                    PaymentMethodsView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Billing History",
                    subtitle: "View past invoices",
                    icon: "doc.text.fill",
                    color: NuraColors.secondary
                ) {
                    showingBillingHistory = true
                }
                .sheet(isPresented: $showingBillingHistory) {
                    BillingHistoryView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
            }
            .background(
                isDark
                    ? AnyView(NuraColors.cardDark)
                    : AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
}

struct SupportSectionView: View {
    var isDark: Bool
    @State private var showingHelp = false
    @State private var showingHelpAndFAQ = false
    @State private var showingContactSupport = false
    @State private var showingRateNura = false
    @State private var showingAbout = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Support")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Help & FAQ",
                    subtitle: "Find answers",
                    icon: "questionmark.circle.fill",
                    color: NuraColors.secondary
                ) {
                    showingHelpAndFAQ = true
                }
                .sheet(isPresented: $showingHelpAndFAQ) {
                    HelpAndFAQView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Contact Support",
                    subtitle: "Get in touch",
                    icon: "envelope.fill",
                    color: NuraColors.success
                ) {
                    showingContactSupport = true
                }
                .sheet(isPresented: $showingContactSupport) {
                    ContactSupportView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Rate App",
                    subtitle: "Share your feedback",
                    icon: "star.fill",
                    color: NuraColors.secondary
                ) {
                    showingRateNura = true
                }
                .sheet(isPresented: $showingRateNura) {
                    RateNuraView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "About",
                    subtitle: "Version 1.0.0",
                    icon: "info.circle.fill",
                    color: NuraColors.textSecondary
                ) {
                    showingAbout = true
                }
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
            }
            .background(
                isDark
                    ? AnyView(NuraColors.cardDark)
                    : AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        // .sheet(isPresented: $showingHelp) {
        //     HelpView()
        // }
    }
}

struct SignOutButton: View {
    var isDark: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Button(action: {
            Task { await authManager.signOut() }
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDark ? NuraColors.errorDark.opacity(0.15) : Color.red.opacity(0.1))
            .foregroundColor(isDark ? NuraColors.errorDark : NuraColors.error)
            .cornerRadius(12)
        }
    }
}

// Placeholder views for sheets
struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nura Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock advanced features and personalized recommendations")
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Customize your Nura experience")
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Help & FAQ")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Find answers to common questions")
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// Elegant, aesthetic personal info view with Supabase integration
struct PersonalInformationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var selectedCountryCode: CountryCode = CountryCode.allCountries.first { $0.dialCode == "+1" } ?? CountryCode.allCountries[0]
    @State private var profileImage: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var isLoading = true
    @State private var saveSuccess: Bool? = nil // nil: idle, true: success, false: error
    @State private var errorMessage: String? = nil
    @State private var lastUpdated: Date? = nil
    @State private var hasChanges = false
    
    // Store original values to detect changes
    @State private var originalName: String = ""
    @State private var originalEmail: String = ""
    @State private var originalPhone: String = ""
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    
    private var completionPercentage: Double {
        var completed = 0.0
        let total = 3.0
        
        if !name.trimmingCharacters(in: .whitespaces).isEmpty { completed += 1 }
        if !email.trimmingCharacters(in: .whitespaces).isEmpty { completed += 1 }
        if !phone.trimmingCharacters(in: .whitespaces).isEmpty { completed += 1 }
        
        return completed / total
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with subtle animation
                LinearGradient(
                    gradient: Gradient(colors: [
                        NuraColors.sand.opacity(0.95),
                        NuraColors.primary.opacity(0.25),
                        NuraColors.secondary.opacity(0.18),
                        NuraColors.sage.opacity(0.18)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: saveSuccess)
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: NuraColors.primary))
                            .scaleEffect(1.2)
                        Text("Loading your information...")
                            .font(.subheadline)
                            .foregroundColor(NuraColors.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Enhanced profile image section
                            VStack(spacing: 12) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let profileImage = profileImage {
                                        profileImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(NuraColors.primary, lineWidth: 3))
                                            .shadow(color: NuraColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .accessibilityLabel("Profile photo")
                                    } else {
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [NuraColors.primary, NuraColors.secondary]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.white)
                                            )
                                            .shadow(color: NuraColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                            .accessibilityLabel("Default profile photo")
                                    }
                                    
                                    Button(action: { 
                                        showingImagePicker = true
                                        // Add haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(NuraColors.background)
                                                .frame(width: 32, height: 32)
                                                .shadow(radius: 3)
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(NuraColors.primary)
                                        }
                                    }
                                    .accessibilityLabel("Edit profile photo")
                                    .offset(x: 6, y: 6)
                                    .scaleEffect(showingImagePicker ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3), value: showingImagePicker)
                                }
                                
                                // Completion indicator
                                VStack(spacing: 4) {
                                    ProgressView(value: completionPercentage)
                                        .progressViewStyle(LinearProgressViewStyle(tint: NuraColors.primary))
                                        .frame(width: 120)
                                    Text("\(Int(completionPercentage * 100))% Complete")
                                        .font(.caption2)
                                        .foregroundColor(NuraColors.textSecondary)
                                }
                            }
                            .padding(.top, 16)
                            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                                ImagePicker(image: $inputImage)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Personal Information")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .accessibilityAddTraits(.isHeader)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.caption)
                                        .foregroundColor(NuraColors.success)
                                    Text("Your data is encrypted and secure")
                                        .font(.caption)
                                        .foregroundColor(NuraColors.textSecondary)
                                }
                            }
                            
                            // Enhanced form fields
                            VStack(spacing: 20) {
                                FormField(
                                    title: "Full Name",
                                    subtitle: "Required • How should we address you?",
                                    icon: "person.fill",
                                    text: $name,
                                    isRequired: true,
                                    hasChanges: name != originalName,
                                    cardBackground: cardBackground
                                )
                                
                                FormField(
                                    title: "Email Address",
                                    subtitle: "Required • For account access and updates",
                                    icon: "envelope.fill",
                                    text: $email,
                                    isRequired: true,
                                    keyboardType: .emailAddress,
                                    hasChanges: email != originalEmail,
                                    cardBackground: cardBackground,
                                    isDisabled: true // Email comes from auth
                                )
                                
                                PhoneFormField(
                                    title: "Phone Number",
                                    subtitle: "Optional • For important notifications",
                                    icon: "phone.fill",
                                    phoneNumber: $phone,
                                    selectedCountryCode: $selectedCountryCode,
                                    isRequired: false,
                                    hasChanges: phone != originalPhone,
                                    cardBackground: cardBackground
                                )
                                
                                // Privacy notice for phone storage
                                if !phone.trimmingCharacters(in: .whitespaces).isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(NuraColors.secondary)
                                            .font(.caption)
                                        Text("Phone numbers are stored securely in your account for cross-device access")
                                            .font(.caption2)
                                            .foregroundColor(NuraColors.textSecondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(NuraColors.secondary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 12)
                            
                            // Enhanced save section
                            VStack(spacing: 12) {
                                Button(action: saveInfo) {
                                    HStack(spacing: 12) {
                                        if isSaving {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        }
                                        Text(isSaving ? "Saving..." : (hasChanges ? "Save Changes" : "All Saved"))
                                            .fontWeight(.semibold)
                                        
                                        if !hasChanges && !isSaving {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        hasChanges ? NuraColors.primary : NuraColors.success
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .shadow(color: (hasChanges ? NuraColors.primary : NuraColors.success).opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                .disabled(isSaving || !hasChanges)
                                .scaleEffect(isSaving ? 0.98 : 1.0)
                                .animation(.spring(response: 0.3), value: isSaving)
                                .accessibilityLabel("Save personal information")
                                
                                // Status messages
                                if let saveSuccess = saveSuccess {
                                    if saveSuccess {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(NuraColors.success)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Information saved successfully!")
                                                    .foregroundColor(NuraColors.success)
                                                    .fontWeight(.medium)
                                                if let lastUpdated = lastUpdated {
                                                    Text("Last updated: \(lastUpdated, formatter: timeFormatter)")
                                                        .font(.caption)
                                                        .foregroundColor(NuraColors.textSecondary)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(NuraColors.success.opacity(0.1))
                                        .cornerRadius(10)
                                        .transition(.slide.combined(with: .opacity))
                                        .accessibilityLabel("Information saved successfully")
                                    } else {
                                        HStack(spacing: 8) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(NuraColors.error)
                                            Text(errorMessage ?? "Error saving information")
                                                .foregroundColor(NuraColors.error)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(NuraColors.error.opacity(0.1))
                                        .cornerRadius(10)
                                        .transition(.slide.combined(with: .opacity))
                                        .accessibilityLabel("Error saving information")
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            
                            Spacer(minLength: 20)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear {
                loadUserData()
            }
            .onChange(of: name) { oldValue, newValue in updateHasChanges() }
            .onChange(of: email) { oldValue, newValue in updateHasChanges() }
            .onChange(of: phone) { oldValue, newValue in updateHasChanges() }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
    
    private func updateHasChanges() {
        hasChanges = name != originalName || email != originalEmail || phone != originalPhone
    }
    
    private func loadUserData() {
        guard let user = authManager.session?.user else {
            isLoading = false
            return
        }
        
        // Load data from auth user
        email = user.email ?? ""
        originalEmail = email
        
        // Use the proper display name logic that respects tempUserName priority
        // This handles the case where userProfile.name might be empty but tempUserName has the value
        // The getDisplayName() function has proper fallback logic: tempUserName -> userProfile.name -> "User"
        name = authManager.getDisplayName()
        
        // Load phone from user profile if available
        if let userProfile = authManager.userProfile {
            let savedPhone = userProfile.phone ?? ""
            
            // Parse the phone number to extract country code and local number
            if !savedPhone.isEmpty {
                // Try to find the country code from the saved phone number
                for country in CountryCode.allCountries {
                    if savedPhone.hasPrefix(country.dialCode) {
                        selectedCountryCode = country
                        phone = String(savedPhone.dropFirst(country.dialCode.count))
                        break
                    }
                }
                
                // If no country code found, assume US (+1)
                if phone.isEmpty {
                    phone = savedPhone
                }
            } else {
                phone = ""
            }
            
            print("📱 Loaded phone from profiles table: '\(savedPhone)' -> country: \(selectedCountryCode.dialCode), local: '\(phone)'")
        } else {
            // Fallback to auth metadata for name if no profile exists
            let userMetadata = user.userMetadata
            if let metaName = userMetadata["name"]?.stringValue {
                name = metaName
            } else if let fullName = userMetadata["full_name"]?.stringValue {
                name = fullName
            }
            phone = ""
            print("📱 No phone found in profiles table, using empty string")
        }
        
        originalName = name
        originalPhone = phone
        updateHasChanges()
        
        // Load existing profile image if available
        loadExistingProfileImage()
        
        isLoading = false
    }
    
    private func loadExistingProfileImage() {
        guard let userProfile = authManager.userProfile else {
            print("📸 No user profile available for loading image")
            return
        }
        
        let profileImageKey = "profile_image_\(userProfile.id.lowercased())"
        print("📸 Loading profile image for user: \(userProfile.id)")
        print("📸 Profile image key: \(profileImageKey)")
        
        // Try to load the profile image from UserDefaults
        if let imageData = UserDefaults.standard.data(forKey: profileImageKey),
           let uiImage = UIImage(data: imageData) {
            profileImage = Image(uiImage: uiImage)
            print("✅ Profile image loaded successfully for user: \(userProfile.id)")
        } else {
            print("📸 No existing profile image found for user: \(userProfile.id)")
            // Clear any existing image to show default state
            profileImage = nil
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        
        // Set the profile image immediately for better UX
        profileImage = Image(uiImage: inputImage)
        
        // Save the profile image to UserDefaults with proper user ID
        guard let userProfile = authManager.userProfile else {
            print("❌ No user profile available for saving image")
            return
        }
        
        let profileImageKey = "profile_image_\(userProfile.id.lowercased())"
        
        if let imageData = inputImage.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
            UserDefaults.standard.synchronize() // Force immediate save
            
            print("✅ Profile image saved for user: \(userProfile.id)")
            print("✅ Profile image key: \(profileImageKey)")
            print("✅ Image data size: \(imageData.count) bytes")
            
            // Verify the save was successful
            if let savedData = UserDefaults.standard.data(forKey: profileImageKey) {
                print("✅ Profile image save verified - data size: \(savedData.count) bytes")
            } else {
                print("❌ Profile image save verification failed")
            }
        } else {
            print("❌ Failed to convert image to JPEG data")
        }
        
        // Mark that we have changes to save
        hasChanges = true
    }
    
    private func saveInfo() {
        // Reset feedback
        saveSuccess = nil
        errorMessage = nil
        
        // Validate
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            saveSuccess = false
            errorMessage = "Name is required"
            return
        }
        guard isValidEmail(email) else {
            saveSuccess = false
            errorMessage = "Please enter a valid email address"
            return
        }
        // Phone is optional, but if provided, validate
        if !phone.trimmingCharacters(in: .whitespaces).isEmpty {
            let fullPhoneNumber = selectedCountryCode.dialCode + phone.filter { $0.isNumber }
            if !isValidPhoneNumber(fullPhoneNumber) {
                saveSuccess = false
                errorMessage = "Please enter a valid phone number"
                return
            }
        }
        
        isSaving = true
        
        Task {
            do {
                // Update user profile in Supabase
                try await updateUserProfile()
                
                await MainActor.run {
                    isSaving = false
                    saveSuccess = true
                    lastUpdated = Date()
                    originalName = name
                    originalEmail = email
                    originalPhone = phone
                    updateHasChanges()
                    
                    // Haptic feedback for success
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                }
                
                // Auto-hide success message after 3 seconds
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    if saveSuccess == true {
                        withAnimation(.easeOut(duration: 0.5)) {
                            saveSuccess = nil
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveSuccess = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    
                    // Haptic feedback for error
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func updateUserProfile() async throws {
        guard let userId = authManager.session?.user.id else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        
        // Format phone number with country code
        let formattedPhone = trimmedPhone.isEmpty ? nil : (selectedCountryCode.dialCode + trimmedPhone.filter { $0.isNumber })
        
        print("📱 Updating profile with phone: '\(formattedPhone ?? "nil")'")
        print("📱 Phone is empty: \(trimmedPhone.isEmpty)")
        
        // First, update the auth user metadata
        try await authManager.client.auth.update(user: UserAttributes(data: ["name": AnyJSON.string(trimmedName)]))
        
        // Create a proper struct for the profile data
        struct ProfileUpdateData: Codable {
            let id: String
            let name: String
            let email: String
            let phone: String?
            let updated_at: String
        }
        
        let profileData = ProfileUpdateData(
            id: userId.uuidString,
            name: trimmedName,
            email: email,
            phone: formattedPhone,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        print("📱 Sending profile update to Supabase with phone: \(profileData.phone ?? "nil")")
        
        // Try to upsert the profile with proper error handling
        do {
            try await authManager.client
                .from("profiles")
                .upsert(profileData)
                .execute()
            
            print("✅ Profile updated successfully in Supabase profiles table")
            print("✅ Phone saved: \(profileData.phone ?? "nil")")
        } catch {
            print("❌ Error updating profile: \(error)")
            print("❌ Error type: \(type(of: error))")
            
            // Handle different error types
            if let postgrestError = error as? PostgrestError {
                print("❌ PostgrestError: \(postgrestError)")
                throw postgrestError
            } else if let authError = error as? AuthError {
                print("❌ AuthError: \(authError)")
                throw authError
            } else {
                print("❌ Unknown error type: \(type(of: error))")
                throw error
            }
        }
        
        // Refresh the user profile in auth manager
        await authManager.refreshUserProfile()
    }
    
    private func createProfilesTableIfNeeded() async throws {
        // This would typically be done via Supabase migrations
        // For now, we'll handle the 404 error gracefully
        print("ℹ️ Please create the profiles table in your Supabase dashboard with the following columns:")
        print("   - id (uuid, primary key)")
        print("   - name (text)")
        print("   - email (text)")
        print("   - phone (text, nullable)")
        print("   - created_at (timestamp)")
        print("   - updated_at (timestamp)")
        
        // For development, you can create this table manually in Supabase Dashboard
        // Go to: Database > Tables > Create new table
        throw NSError(
            domain: "DatabaseError", 
            code: 404, 
            userInfo: [
                NSLocalizedDescriptionKey: "Profiles table not found. Please create it in your Supabase dashboard with the required columns."
            ]
        )
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^[\\d\\s\\-\\(\\)\\+\\.]{7,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone.filter { $0.isNumber || "()- +.".contains($0) })
    }
}

// Enhanced form field component
struct FormField: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var text: String
    let isRequired: Bool
    var keyboardType: UIKeyboardType = .default
    let hasChanges: Bool
    let cardBackground: Color
    var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .secondary : NuraColors.textSecondary)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(NuraColors.error)
                }
                
                if hasChanges {
                    Circle()
                        .fill(NuraColors.primary)
                        .frame(width: 6, height: 6)
                        .animation(.spring(response: 0.3), value: hasChanges)
                }
                
                Spacer()
            }
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(NuraColors.textSecondary.opacity(0.8))
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? NuraColors.primary : NuraColors.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                TextField("", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isFocused ? NuraColors.primary : (hasChanges ? NuraColors.primary.opacity(0.5) : Color.clear),
                                        lineWidth: isFocused ? 2 : 1
                                    )
                            )
                    )
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .disabled(isDisabled)
                    .focused($isFocused)
                    .accessibilityLabel(title)
                    .foregroundColor(isDisabled ? NuraColors.textSecondary.opacity(0.6) : .primary)
                    .scaleEffect(isFocused ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3), value: isFocused)
                
                if isDisabled {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(NuraColors.textSecondary.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Phone Form Field Component
struct PhoneFormField: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var phoneNumber: String
    @Binding var selectedCountryCode: CountryCode
    let isRequired: Bool
    let hasChanges: Bool
    let cardBackground: Color
    
    @FocusState private var isFocused: Bool
    @State private var showingCountryPicker = false
    @State private var phoneValidationStatus: PhoneValidationStatus = .neutral
    @Environment(\.colorScheme) private var colorScheme
    
    enum PhoneValidationStatus {
        case neutral, valid, invalid
        
        var color: Color {
            switch self {
            case .neutral: return .clear
            case .valid: return .green
            case .invalid: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .neutral: return ""
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .secondary : NuraColors.textSecondary)
                
                if isRequired {
                    Text("*")
                        .font(.caption)
                        .foregroundColor(NuraColors.error)
                }
                
                if hasChanges {
                    Circle()
                        .fill(NuraColors.primary)
                        .frame(width: 6, height: 6)
                        .animation(.spring(response: 0.3), value: hasChanges)
                }
                
                Spacer()
            }
            
            Text(subtitle)
                .font(.caption2)
                .italic()
                .foregroundColor(NuraColors.textSecondary.opacity(0.8))
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isFocused ? NuraColors.primary : NuraColors.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // Country Code Button
                Button(action: { showingCountryPicker = true }) {
                    HStack(spacing: 4) {
                        Text(selectedCountryCode.flag)
                            .font(.title3)
                        Text(selectedCountryCode.dialCode)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(NuraColors.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Phone Number TextField
                TextField("Phone number", text: $phoneNumber)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isFocused ? NuraColors.primary : (hasChanges ? NuraColors.primary.opacity(0.5) : phoneValidationStatus.color),
                                        lineWidth: isFocused ? 2 : 1
                                    )
                            )
                    )
                    .keyboardType(.phonePad)
                    .focused($isFocused)
                    .accessibilityLabel(title)
                    .scaleEffect(isFocused ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3), value: isFocused)
                    .onChange(of: phoneNumber) { oldValue, newValue in
                        validatePhoneNumber()
                    }
                
                // Validation Icon
                if phoneValidationStatus != .neutral {
                    Image(systemName: phoneValidationStatus.icon)
                        .foregroundColor(phoneValidationStatus.color)
                        .font(.caption)
                        .animation(.spring(response: 0.3), value: phoneValidationStatus)
                }
            }
        }
        .sheet(isPresented: $showingCountryPicker) {
            CountryCodePickerView(selectedCountryCode: $selectedCountryCode)
        }
    }
    
    private func validatePhoneNumber() {
        guard !phoneNumber.isEmpty else {
            phoneValidationStatus = .neutral
            return
        }
        
        let fullNumber = selectedCountryCode.dialCode + phoneNumber.filter { $0.isNumber }
        phoneValidationStatus = isValidPhoneNumber(fullNumber) ? .valid : .invalid
    }
}

// MARK: - Country Code Picker View
struct CountryCodePickerView: View {
    @Binding var selectedCountryCode: CountryCode
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var filteredCountries: [CountryCode] {
        if searchText.isEmpty {
            return CountryCode.allCountries
        } else {
            return CountryCode.allCountries.filter { country in
                country.name.localizedCaseInsensitiveContains(searchText) ||
                country.dialCode.localizedCaseInsensitiveContains(searchText) ||
                country.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search countries", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Country List
                List(filteredCountries, id: \.id) { country in
                    Button(action: {
                        selectedCountryCode = country
                        dismiss()
                    }) {
                        HStack {
                            Text(country.flag)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(country.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(country.dialCode)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if country.id == selectedCountryCode.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(NuraColors.primary)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// Enhanced ImagePicker for profile photo selection with save option
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { 
                return 
            }
            
            provider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error loading image: \(error)")
                        return
                    }
                    
                    if let selectedImage = image as? UIImage {
                        // Optimize the image for profile photo
                        let optimizedImage = self.optimizeImageForProfile(selectedImage)
                        self.parent.image = optimizedImage
                        
                        // Don't automatically save to Photos app - let user choose if they want to keep it
                        print("✅ Profile photo optimized and ready for use")
                    }
                }
            }
        }
        
        private func optimizeImageForProfile(_ image: UIImage) -> UIImage {
            // Resize to reasonable profile photo size (200x200)
            let targetSize = CGSize(width: 200, height: 200)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            
            return renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    }
}



struct PrivacyAndSecurityView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var trackingEnabled: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showFinalConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    @State private var deleteError: String? = nil
    @State private var confirmationText: String = ""
    @State private var deletionSuccessful: Bool = false
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [NuraColors.sand, NuraColors.sage.opacity(0.18), NuraColors.primary.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(alignment: .center, spacing: 28) {
                    Text("Privacy & Security")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .accessibilityAddTraits(.isHeader)
                    // App Tracking
                    VStack(alignment: .center, spacing: 8) {
                        Text("Allow App Tracking")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Toggle(isOn: $trackingEnabled) {
                            EmptyView()
                        }
                        .toggleStyle(SwitchToggleStyle(tint: NuraColors.primary))
                        .accessibilityLabel("Allow App Tracking")
                        .frame(maxWidth: 80)
                        .padding(.bottom, 2)
                        Text("Let Nura use Apple's App Tracking Transparency to personalize your experience. You can change this anytime in your device settings.")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .secondary : Color.primary.opacity(0.75))
                            .multilineTextAlignment(.center)
                        Text("Legal: We respect your privacy. Your data is never sold. See our Privacy Policy for details.")
                            .font(.caption2)
                            .foregroundColor(colorScheme == .dark ? .secondary : Color.primary.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(12)
                    // Data Download/Export
                    VStack(alignment: .center, spacing: 8) {
                        Text("Download Your Data")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Request a copy of your personal data stored with Nura. We'll email you a download link.")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .secondary : Color.primary.opacity(0.75))
                            .multilineTextAlignment(.center)
                        Button(action: {/* TODO: Implement data export */}) {
                            Text("Request Data Export")
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(NuraColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Request Data Export")
                    }
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(12)
                    // Delete Account
                    VStack(alignment: .center, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(NuraColors.errorStrong)
                                .font(.title3)
                            Text("Delete My Account")
                                .font(.headline)
                                .foregroundColor(NuraColors.errorStrong)
                        }
                        
                        VStack(spacing: 8) {
                            Text("⚠️ This will permanently deactivate:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(NuraColors.errorStrong)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("•")
                                    Text("Your account and profile data")
                                }
                                HStack {
                                    Text("•")
                                    Text("All skin analysis history")
                                }
                                HStack {
                                    Text("•")
                                    Text("Skin diary entries and progress")
                                }
                                HStack {
                                    Text("•")
                                    Text("Subscription and billing data")
                                }
                                HStack {
                                    Text("•")
                                    Text("App preferences and settings")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(NuraColors.errorStrong.opacity(0.8))
                            
                            Text("This action cannot be undone!")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(NuraColors.errorStrong)
                                .padding(.top, 4)
                        }
                        
                        // Show success message if deletion was successful
                        if deletionSuccessful {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Account deactivated successfully. Redirecting to login...")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        // Show error if deletion failed
                        else if let deleteError = deleteError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(NuraColors.errorStrong)
                                Text(deleteError)
                                    .font(.caption)
                                    .foregroundColor(NuraColors.errorStrong)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(NuraColors.errorStrong.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            if isDeleting || deletionSuccessful {
                                return // Prevent multiple taps
                            }
                            showDeleteAlert = true
                        }) {
                            HStack(spacing: 12) {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else if deletionSuccessful {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                }
                                Text(isDeleting ? "Deactivating Account..." : (deletionSuccessful ? "Account Deactivated" : "Deactivate Account"))
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                isDeleting ? NuraColors.errorStrong.opacity(0.6) : 
                                (deletionSuccessful ? Color.green : NuraColors.errorStrong)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isDeleting || deletionSuccessful)
                        .accessibilityLabel("Delete Account")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(NuraColors.errorStrong.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .alert("⚠️ Deactivate Account", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Continue", role: .destructive) {
                            showFinalConfirmation = true
                        }
                    } message: {
                        Text("Are you absolutely sure? This will permanently deactivate your account and remove all data. This action cannot be undone.")
                    }
                    .sheet(isPresented: $showFinalConfirmation) {
                        DeleteAccountConfirmationView(
                            isDeleting: $isDeleting,
                            deleteError: $deleteError,
                            onConfirmDelete: deleteAccount
                        )
                        .environmentObject(authManager)
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    // MARK: - Account Deletion Logic
    private func deleteAccount() {
        Task {
            do {
                isDeleting = true
                deleteError = nil
                
                // Add a small delay for better UX feedback
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                try await authManager.deleteAccount()
                
                // Account deletion successful - dismiss all modals and redirect to login
                await MainActor.run {
                    deletionSuccessful = true
                    
                    // Haptic feedback for success
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Dismiss the confirmation modal
                    showFinalConfirmation = false
                    
                    // Dismiss the privacy & security modal
                    dismiss()
                    
                    // Show success message briefly before redirecting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // The auth state change will automatically redirect to login
                        // but we can also force a sign out to ensure clean state
                        Task {
                            await authManager.signOut()
                        }
                    }
                }
                
            } catch {
                isDeleting = false
                deleteError = error.localizedDescription
                
                // Haptic feedback for error
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                print("❌ Account deletion failed: \(error)")
            }
        }
    }
}

// MARK: - Delete Account Confirmation View
struct DeleteAccountConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isDeleting: Bool
    @Binding var deleteError: String?
    let onConfirmDelete: () -> Void
    
    @State private var confirmationText: String = ""
    @State private var hasTypedCorrectly: Bool = false
    
    private let requiredText = "DELETE MY ACCOUNT"
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.8) : .white
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background
                LinearGradient(
                    gradient: Gradient(colors: [
                        NuraColors.errorStrong.opacity(0.05),
                        NuraColors.errorStrong.opacity(0.02),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(NuraColors.errorStrong)
                                .scaleEffect(isDeleting ? 0.8 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isDeleting)
                            
                            Text("⚠️ Final Confirmation")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(NuraColors.errorStrong)
                            
                            Text("This is your last chance to reconsider.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Critical info card
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                Text("What happens next:")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("1.")
                                        .fontWeight(.bold)
                                        .foregroundColor(NuraColors.errorStrong)
                                    Text("Your user account will be permanently deleted from our servers")
                                }
                                HStack {
                                    Text("2.")
                                        .fontWeight(.bold)
                                        .foregroundColor(NuraColors.errorStrong)
                                    Text("All your data will be immediately and permanently removed")
                                }
                                HStack {
                                    Text("3.")
                                        .fontWeight(.bold)
                                        .foregroundColor(NuraColors.errorStrong)
                                    Text("You will be logged out and cannot recover this account")
                                }
                                HStack {
                                    Text("4.")
                                        .fontWeight(.bold)
                                        .foregroundColor(NuraColors.errorStrong)
                                    Text("This action cannot be undone - no backups exist")
                                }
                            }
                            .font(.subheadline)
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Confirmation input
                        VStack(spacing: 12) {
                            Text("Type '\(requiredText)' to confirm:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(NuraColors.errorStrong)
                            
                            TextField("Type here to confirm", text: $confirmationText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    hasTypedCorrectly ? Color.green : (confirmationText.isEmpty ? Color.gray.opacity(0.3) : NuraColors.errorStrong),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .onChange(of: confirmationText) { oldValue, newValue in
                                    hasTypedCorrectly = (newValue.uppercased() == requiredText)
                                }
                            
                            if !confirmationText.isEmpty && !hasTypedCorrectly {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(NuraColors.errorStrong)
                                    Text("Please type exactly: '\(requiredText)'")
                                        .font(.caption)
                                        .foregroundColor(NuraColors.errorStrong)
                                }
                            } else if hasTypedCorrectly {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Confirmation text correct")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(12)
                        
                        // Error display
                        if let deleteError = deleteError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(NuraColors.errorStrong)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Deletion Failed")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(NuraColors.errorStrong)
                                    Text(deleteError)
                                        .font(.caption)
                                        .foregroundColor(NuraColors.errorStrong.opacity(0.8))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(NuraColors.errorStrong.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                if !isDeleting && hasTypedCorrectly {
                                    onConfirmDelete()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    if isDeleting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "trash.fill")
                                    }
                                    Text(isDeleting ? "Deleting Account..." : "DELETE MY ACCOUNT PERMANENTLY")
                                        .fontWeight(.bold)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    hasTypedCorrectly && !isDeleting ? NuraColors.errorStrong : NuraColors.errorStrong.opacity(0.5)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!hasTypedCorrectly || isDeleting)
                            .accessibilityLabel("Permanently delete account")
                            
                            Button("Cancel - Keep My Account", action: {
                                dismiss()
                            })
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .disabled(isDeleting)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    if !isDeleting {
                        dismiss()
                    }
                }
                .disabled(isDeleting)
            )
        }
        .interactiveDismissDisabled(isDeleting)
    }
}

// 1. Create AppPreferencesPageView as a NavigationLink destination
struct AppPreferencesPageView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    @State private var tempColorSchemePreference: String = "light"
    @State private var showSaved: Bool = false
    let colorOptions = ["light": "Light", "dark": "Dark", "system": "System Default"]
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        // Default to light mode for new users or users who had "system" set
        let savedPreference = UserDefaults.standard.string(forKey: "colorSchemePreference")
        let initialValue = (savedPreference == nil || savedPreference == "system") ? "light" : savedPreference!
        _tempColorSchemePreference = State(initialValue: initialValue)
    }
    var body: some View {
        VStack(alignment: .center, spacing: 28) {
            Text("App Preferences")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .animation(.easeInOut, value: tempColorSchemePreference)
            Text("Dark mode reduces eye strain and saves battery in low-light environments. Choose your preferred appearance below.")
                .font(.subheadline)
                .foregroundColor(tempColorSchemePreference == "dark" ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .animation(.easeInOut, value: tempColorSchemePreference)
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    AppearanceSwitchRow(
                        title: "Light",
                        icon: "sun.max.fill",
                        isOn: tempColorSchemePreference == "light",
                        color: NuraColors.primary,
                        onTap: { tempColorSchemePreference = "light" }
                    )
                    AppearanceSwitchRow(
                        title: "Dark",
                        icon: "moon.fill",
                        isOn: tempColorSchemePreference == "dark",
                        color: NuraColors.accentDark,
                        onTap: { tempColorSchemePreference = "dark" }
                    )
                    AppearanceSwitchRow(
                        title: "System Default",
                        icon: "circle.lefthalf.filled",
                        isOn: tempColorSchemePreference == "system",
                        color: NuraColors.secondary,
                        onTap: { tempColorSchemePreference = "system" }
                    )
                }
                .padding(.vertical, 8)
                .background(tempColorSchemePreference == "dark" ? NuraColors.cardDark : NuraColors.card)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Choose between light, dark, or system default appearance.")
                .animation(.easeInOut, value: tempColorSchemePreference)
                // Info/warning message for logout
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    Text("For your changes to take effect, you will be signed out and must log in again after saving your appearance settings.")
                        .font(.footnote)
                        .foregroundColor(NuraColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(10)
                .background(NuraColors.card.opacity(0.7))
                .cornerRadius(8)
                .padding(.bottom, 4)
                Button(action: {
                    if appearanceManager.colorSchemePreference != tempColorSchemePreference {
                        appearanceManager.colorSchemePreference = tempColorSchemePreference
                        showSaved = true
                        // Haptic feedback
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        // Show 'Saved!' animation, then log out after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showSaved = false
                            Task { await authManager.signOut() } // Log out the user after showing 'Saved!'
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tempColorSchemePreference == "dark" ? NuraColors.primaryDark : NuraColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
                .accessibilityLabel("Save app preferences")
                .disabled(appearanceManager.colorSchemePreference == tempColorSchemePreference)
                if showSaved {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(tempColorSchemePreference == "dark" ? NuraColors.successDark : NuraColors.success)
                }
            }
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Custom row for appearance switches
struct AppearanceSwitchRow: View {
    let title: String
    let icon: String
    let isOn: Bool
    let color: Color
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 32)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? color : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 28)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: isOn ? 8 : -8)
                        .shadow(radius: 1)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOn)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(isOn ? color.opacity(0.08) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Selected" : "Not selected")
    }
}

// UX/PM suggestions:
// - Consider adding a "System Default" option for color scheme
// - Add a short description about dark mode benefits
// - Optionally, allow previewing dark mode before saving
// - Add haptic feedback on save for delight
// - Make sure all text/buttons have sufficient contrast in both modes
// - Consider accessibility: larger text, VoiceOver labels, etc.

#Preview {
    AppPreferencesPageView(isPresented: .constant(true))
        .environmentObject(AppearanceManager())
        .environmentObject(AuthenticationManager.shared)
} 