*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Desktop
Library           RPA.RobotLogListener
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets

*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order
${csv_url}        https://robotsparebinindustries.com/orders.csv
${img_folder}     ${CURDIR}${/}screenshots
${pdf_folder}     ${CURDIR}${/}order_pdfs
${output_folder}    ${CURDIR}${/}output
${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}robot_orders_pdf.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory build
    Get the favorite flavor from vault
    ${whois}=    Who is running using this robot?
    Open the robot order website
    ${orders}=    Get orders from list
    FOR    ${row}    IN    @{orders}
        Close the popup boy
        Fill out the form    ${row}
        Wait Until Keyword Succeeds    8x    3s    Preview the robot
        Wait Until Keyword Succeeds    8x    3s    Submit the orders
        ${order_boi}    ${img_filename}=    Take a screenshot of the robot
        ${pdf}=    Store the receipt as a PDF file    ORDER_NUMBERS=${order_boi}
        Embed the robot screenshot to the receipt    IMG_FILE=${img_filename}    PDF_FILE=${pdf}
        Go to order another robot
        Log To Console    Order Seccessful!
    END
    Create a ZIP file of the receipts
    Log Out And Close The Browser
    All orders have been placed!    name=${whois}

*** Keywords ***
Open the robot order website
    Open Available Browser    ${url}

Directory build
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}
    Empty Directory    ${output_folder}

Get orders from list
    Download    ${csv_url}    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    [Return]    ${table}

Close the popup boy
    Click Button    Yep

Fill out the form
    [Arguments]    ${therow}
    #Get the Values from the dictionary
    Set Local Variable    ${order_num}    ${therow}[Order number]
    Set Local Variable    ${head}    ${therow}[Head]
    Set Local Variable    ${body}    ${therow}[Body]
    Set Local Variable    ${legs}    ${therow}[Legs]
    Set Local Variable    ${address}    ${therow}[Address]
    #Get the Values from the UI elements
    Set Local Variable    ${form_input_head}    //*[@id="head"]
    Set Local Variable    ${form_input_body}    body
    Set Local Variable    ${form_input_legs}    xpath://html/body/div/div/div/div/div/form/div/input
    Set Local Variable    ${form_input_address}    //*[@id="address"]
    Set Local Variable    ${button_peview}    //*[@id="preview"]
    Set Local Variable    ${button_order}    //*[@id="order"]
    Set Local Variable    ${robot_preview}    //*[@id="robot-preview-image"]
    #Place data into the correct fields
    #Head Input
    Wait Until Element Is Visible    ${form_input_head}
    Wait Until Element Is Enabled    ${form_input_head}
    Select From List By Value    ${form_input_head}    ${head}
    #Body Input
    Wait Until Element Is Enabled    ${form_input_body}
    Select Radio Button    ${form_input_body}    ${body}
    #Legs Input
    Wait Until Element Is Enabled    ${form_input_legs}
    Input Text    ${form_input_legs}    ${legs}
    #Address Input
    Wait Until Element Is Enabled    ${form_input_address}
    Input Text    ${form_input_address}    ${address}

Preview the robot
    Wait Until Element Is Enabled    //*[@id="preview"]
    Click Button    //*[@id="preview"]
    Wait Until Element Is Visible    id:robot-preview-image

Submit the orders
    Set Local Variable    ${button_order}    //*[@id="order"]
    Set Local Variable    ${robot_receipt}    //*[@id="receipt"]
    Mute Run On Failure    Page Should Contain Element
    Click Button    ${button_order}
    Page Should Contain Element    ${robot_receipt}

Take a screenshot of the robot
    Set Local Variable    ${order_boi}    css:.badge-success
    Set Local Variable    ${robot_preview}    id:robot-preview-image
    Sleep    0.5sec
    ${order_boi}    Get Text    css:.badge-success
    Set Local Variable    ${screenshot_file_name}    ${img_folder}${/}${order_boi}.png
    Sleep    2sec
    Capture Element Screenshot    ${robot_preview}    ${screenshot_file_name}
    [Return]    ${order_boi}    ${screenshot_file_name}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBERS}
    Wait Until Element Is Visible    //*[@id="receipt"]
    ${order_receipt_code}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${pdf_filename_}    ${pdf_folder}${/}${ORDER_NUMBERS}.pdf
    Html To Pdf    content=${order_receipt_code}    output_path=${pdf_filename_}
    [Return]    ${pdf_filename_}

Embed the robot screenshot to the receipt
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Open PDF    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}
    Close PDF    ${PDF_FILE}

Go to order another robot
    Click Button    //*[@id="order-another"]

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Log Out And Close The Browser
    Close Browser

Get the favorite flavor from vault
    ${secret_vault}=    Get Secret    thesecrets
    Log    ${secret_vault}[myfavouriteicecream] is my favorite ice cream.    console=yes

Who is running using this robot?
    Add heading    I am your lord and savior. Who dares to run this robot?
    Add text input    name    label=What is your name?    placeholder=Input your name here.
    ${result}=    Run dialog
    [Return]    ${result.name}

All orders have been placed!
    [Arguments]    ${name}
    Add heading    Your orders have been placed!
    Add text    ${name} your thing is all done. Go do something else!
    Run dialog    title=Success
