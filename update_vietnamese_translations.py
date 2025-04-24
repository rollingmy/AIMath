import json
import os

# Path to the JSON file
json_file_path = 'AITimoMath/AITimoMath/Data/timo_questions.json'

# Load the JSON data
with open(json_file_path, 'r', encoding='utf-8') as file:
    data = json.load(file)

# Count of questions that need translation
english_only_count = 0
updated_count = 0

# Function to check if a question is English-only
def is_english_only(question_text):
    # If the question already contains a newline, it might already have a translation
    if "\n" in question_text:
        return False
    # Check for Vietnamese characters or patterns
    vietnamese_chars = ["ă", "â", "đ", "ê", "ô", "ơ", "ư", "Ă", "Â", "Đ", "Ê", "Ô", "Ơ", "Ư"]
    for char in vietnamese_chars:
        if char in question_text:
            return False
    return True

# Function to translate a question
def add_vietnamese_translation(content):
    if "question" not in content:
        return content, False
    
    question = content["question"]
    
    if not is_english_only(question):
        return content, False
    
    # Simple translations for common questions
    translations = {
        "Find the value of 1 + 9 + 6 + 4 + 2.": "Tìm giá trị của 1 + 9 + 6 + 4 + 2.",
        "Find the value of 16 – 7 – 6.": "Tìm giá trị của 16 – 7 – 6.",
        "In the family, Mina has 3 sisters in total. How many children does Mina's mother have?": "Trong gia đình, Mina có tổng cộng 3 chị em gái. Hỏi mẹ của Mina có bao nhiêu người con?",
        "Mary looks at the calendar. Her birthday is 2 days after today and it is on Friday. Which day of the week is today?": "Mary nhìn vào lịch. Sinh nhật của cô ấy là 2 ngày sau hôm nay và rơi vào thứ Sáu. Hôm nay là thứ mấy trong tuần?",
        "By observing the pattern, what is the number in the space (\"...\") provided?\n0, 5, 10, 15, ...": "Bằng cách quan sát quy luật, số nào cần điền vào chỗ trống (\"...\")?\n0, 5, 10, 15, ...",
        "Ken is 15 years old and Ken's sister is 5 years younger than him. How old is Ken's sister now?": "Ken 15 tuổi và em gái của Ken nhỏ hơn cậu ấy 5 tuổi. Em gái của Ken bao nhiêu tuổi?",
        "What is the value of A such that the equation below is correct?\n19 – A = 8": "Giá trị của A là bao nhiêu để phương trình dưới đây đúng?\n19 – A = 8",
        "According to the pattern below, which number should be filled in the blank?\n20, 1, 19, 2, 18, 3, __": "Theo quy luật dưới đây, số nào nên điền vào chỗ trống?\n20, 1, 19, 2, 18, 3, __",
        "Find the smallest number with two identical digits.": "Tìm số nhỏ nhất có hai chữ số giống nhau.",
        "Separate the following stars into 2 equal groups. How many stars are there in each group?\n******": "Chia các ngôi sao sau thành 2 nhóm bằng nhau. Mỗi nhóm có bao nhiêu ngôi sao?\n******",
        "According to the pattern shown below, what is the letter in the space (\"__\") provided?\nA, D, G, J, M, __, ...": "Theo quy luật hiển thị dưới đây, chữ cái nào cần điền vào chỗ trống (\"__\")?\nA, D, G, J, M, __, ..."
    }
    
    # Add explanation translations
    explanation_translations = {
        "Adding the numbers: 1 + 9 + 6 + 4 + 2 = 22": "Cộng các số: 1 + 9 + 6 + 4 + 2 = 22",
        "Subtracting the numbers: 16 - 7 - 6 = 9 - 6 = 3": "Trừ các số: 16 - 7 - 6 = 9 - 6 = 3",
        "If Mary's birthday is on Friday and it's 2 days after today, then today must be Wednesday.": "Nếu sinh nhật của Mary là vào thứ Sáu và cách hôm nay 2 ngày, thì hôm nay phải là thứ Tư.",
        "Mina has 3 sisters, and Mina herself is also a child of her mother. So in total, Mina's mother has 4 children.": "Mina có 3 chị em gái, và bản thân Mina cũng là một người con của mẹ cô ấy. Vì vậy, tổng cộng mẹ Mina có 4 người con.",
        "The pattern shows numbers increasing by 5 each time. After 15, the next number would be 20.": "Quy luật cho thấy các số tăng lên 5 đơn vị mỗi lần. Sau số 15, số tiếp theo sẽ là 20.",
        "If Ken is 15 years old and his sister is 5 years younger, then his sister is 15 - 5 = 10 years old.": "Nếu Ken 15 tuổi và em gái của cậu ấy nhỏ hơn 5 tuổi, thì em gái cậu ấy là 15 - 5 = 10 tuổi.",
        "We need to solve the equation 19 - A = 8. So A = 19 - 8 = 11.": "Chúng ta cần giải phương trình 19 - A = 8. Vậy A = 19 - 8 = 11.",
        "The pattern is decreasing by 1 for each odd position (20, 19, 18, ...) and increasing by 1 for each even position (1, 2, 3, ...). So after 3, the next number should be 17.": "Quy luật là giảm đi 1 đơn vị cho mỗi vị trí lẻ (20, 19, 18, ...) và tăng 1 đơn vị cho mỗi vị trí chẵn (1, 2, 3, ...). Vì vậy, sau số 3, số tiếp theo nên là 17.",
        "The smallest number with two identical digits is 11, where both digits are 1.": "Số nhỏ nhất có hai chữ số giống nhau là 11, trong đó cả hai chữ số đều là 1.",
        "Divide the total number of stars by 2 to find how many stars should be in each equal group.": "Chia tổng số ngôi sao cho 2 để tìm ra số ngôi sao trong mỗi nhóm bằng nhau.",
        "Based on the pattern in the sequence of letters, we can determine that P is the letter that should go in the blank space.": "Dựa vào quy luật trong chuỗi các chữ cái, chúng ta có thể xác định rằng P là chữ cái nên điền vào chỗ trống."
    }
    
    # Check if we have a translation for this question
    if question in translations:
        # Apply translation
        vn_translation = translations[question]
        content["question"] = question + "\n" + vn_translation
        
        # Update explanation if it exists
        if "explanation" in content and content["explanation"] in explanation_translations:
            content["explanation"] = content["explanation"] + "\n" + explanation_translations[content["explanation"]]
        
        return content, True
    
    # Generic translation (if no specific translation is available)
    return content, False

# Process each question in the data
for item in data:
    if "content" in item:
        updated_content, was_updated = add_vietnamese_translation(item["content"])
        item["content"] = updated_content
        if was_updated:
            updated_count += 1
            print(f"Updated question: {item['content']['question'].split(chr(10))[0] if chr(10) in item['content']['question'] else item['content']['question'][:50]}")
        elif "question" in item["content"] and is_english_only(item["content"]["question"]):
            english_only_count += 1
            print(f"English-only question without translation: {item['content']['question']}")

# Save the updated JSON data back to the file
with open(json_file_path, 'w', encoding='utf-8') as file:
    json.dump(data, file, ensure_ascii=False, indent=2)

print(f"\nTotal English-only questions found: {english_only_count + updated_count}")
print(f"Questions updated with translations: {updated_count}")
print(f"Questions still needing translations: {english_only_count}")
print(f"\nSuccessfully updated the JSON file: {json_file_path}") 