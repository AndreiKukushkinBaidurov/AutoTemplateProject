import streamlit as st
import pandas as pd
import pycountry
import requests
import io
from datetime import datetime

# Set page config
st.set_page_config(
    page_title="Client Data Questionnaire",
    page_icon="🏨",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for modern design with blue and yellow theme
st.markdown("""
<style>
    .main {
        padding-top: 2rem;
    }
    
    .stSelectbox > div > div > select {
        background-color: #E8F4FD;
        border: 2px solid #4A90E2;
    }
    
    .stFileUploader > div > div {
        background-color: #FFF9E6;
        border: 2px solid #FFD700;
        border-radius: 10px;
        padding: 20px;
    }
    
    .metric-card {
        background: linear-gradient(135deg, #4A90E2 0%, #357ABD 100%);
        padding: 20px;
        border-radius: 15px;
        color: white;
        text-align: center;
        margin: 10px 0;
    }
    
    .result-card {
        background: linear-gradient(135deg, #FFD700 0%, #FFC107 100%);
        padding: 20px;
        border-radius: 15px;
        color: #333;
        margin: 10px 0;
    }
    
    .header-style {
        background: linear-gradient(90deg, #1E3A8A 0%, #3B82F6 50%, #FFD700 100%);
        padding: 20px;
        border-radius: 15px;
        text-align: center;
        color: white;
        margin-bottom: 30px;
    }
</style>
""", unsafe_allow_html=True)

# Function to send CSV files to n8n webhook
def send_to_webhook(hotel_quantity, selected_countries, hotel_ids_list):
    """
    Send questionnaire results as 3 CSV files to n8n webhook
    """
    webhook_url = "http://localhost:5678/webhook-test/ClientDataQuestion"
    
    try:
        # Create CSV 1: Configuration Summary
        config_data = {
            'Parameter': ['Hotel Quantity', 'Number of Countries', 'Submission Date', 'Total Hotel IDs'],
            'Value': [
                hotel_quantity,
                len(selected_countries),
                datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                len(hotel_ids_list) if hotel_ids_list else 0
            ]
        }
        config_df = pd.DataFrame(config_data)
        config_csv = config_df.to_csv(index=False)
        
        # Create CSV 2: Selected Countries
        countries_data = {
            'Country_Name': selected_countries,
            'Selection_Order': range(1, len(selected_countries) + 1)
        }
        countries_df = pd.DataFrame(countries_data)
        countries_csv = countries_df.to_csv(index=False)
        
        # Create CSV 3: Hotel IDs (if provided)
        if hotel_ids_list:
            hotels_data = {
                'Hotel_ID': hotel_ids_list,
                'Order': range(1, len(hotel_ids_list) + 1)
            }
            hotels_df = pd.DataFrame(hotels_data)
            hotels_csv = hotels_df.to_csv(index=False)
        else:
            hotels_csv = "Hotel_ID,Order\nNo hotel IDs provided,0"
        
        # Prepare files for multipart upload
        files = {
            'config_summary.csv': ('config_summary.csv', config_csv, 'text/csv'),
            'selected_countries.csv': ('selected_countries.csv', countries_csv, 'text/csv'),
            'hotel_ids.csv': ('hotel_ids.csv', hotels_csv, 'text/csv')
        }
        
        # Additional form data
        data = {
            'submission_type': 'client_questionnaire',
            'timestamp': datetime.now().isoformat(),
            'hotel_quantity': hotel_quantity,
            'countries_count': len(selected_countries),
            'hotel_ids_count': len(hotel_ids_list) if hotel_ids_list else 0
        }
        
        # Send POST request to webhook
        response = requests.post(webhook_url, files=files, data=data, timeout=30)
        
        if response.status_code == 200:
            return True, "Successfully sent to webhook!"
        else:
            return False, f"Webhook returned status code: {response.status_code}"
            
    except requests.exceptions.ConnectionError:
        return False, "Could not connect to webhook. Please ensure n8n is running on localhost:5678"
    except requests.exceptions.Timeout:
        return False, "Request timed out. Please try again."
    except Exception as e:
        return False, f"Error sending to webhook: {str(e)}"

# Header
st.markdown('<div class="header-style"><h1>🏨 Client Data Collection Questionnaire</h1></div>', unsafe_allow_html=True)

# Initialize session state
if 'form_submitted' not in st.session_state:
    st.session_state.form_submitted = False

# Create columns for layout
col1, col2 = st.columns([2, 1])

with col1:
    st.markdown("### 📊 Configuration Settings")
    
    # 1. Hotel Quantity Selection
    st.markdown("#### 1. Number of Hotels in Template")
    hotel_quantity = st.selectbox(
        "Select the quantity of hotels:",
        options=[2500, 5000, 10000],
        index=0,
        help="Choose the number of hotels to include in your template"
    )
    
    # Display selected quantity in a metric card
    st.markdown(f'<div class="metric-card"><h3>{hotel_quantity:,}</h3><p>Hotels Selected</p></div>', unsafe_allow_html=True)
    
    # 2. Country Selection
    st.markdown("#### 2. Top Destinations")
    
    # Get list of all countries
    countries = [country.name for country in pycountry.countries]
    countries.sort()
    
    selected_countries = st.multiselect(
        "Search and select destination countries:",
        options=countries,
        default=["United States", "United Kingdom", "France", "Germany", "Spain"],
        help="You can search and select multiple countries"
    )
    
    # 3. CSV File Upload
    st.markdown("#### 3. Hotel ID Upload")
    uploaded_file = st.file_uploader(
        "Upload CSV file with Hotel IDs (single column)",
        type=['csv'],
        help="Upload a CSV file containing a single column with Hotel IDs"
    )
    
    # Process uploaded file
    if uploaded_file is not None:
        try:
            df = pd.read_csv(uploaded_file)
            
            if len(df.columns) == 1:
                hotel_ids = df.iloc[:, 0].tolist()
                top_1000_hotels = hotel_ids[:1000] if len(hotel_ids) > 1000 else hotel_ids
                
                st.success(f"✅ File uploaded successfully! Found {len(hotel_ids)} Hotel IDs")
                st.info(f"📈 Displaying top {len(top_1000_hotels)} hotels")
                
                # Show preview of hotel IDs
                with st.expander("Preview Hotel IDs"):
                    preview_df = pd.DataFrame(top_1000_hotels[:10], columns=['Hotel ID'])
                    st.dataframe(preview_df)
                    
            else:
                st.error("❌ Please upload a CSV file with exactly one column containing Hotel IDs")
                
        except Exception as e:
            st.error(f"❌ Error reading file: {str(e)}")

with col2:
    st.markdown("### 📋 Summary")
    
    # Summary card
    st.markdown(f"""
    <div class="result-card">
        <h4>📊 Current Selection</h4>
        <p><strong>Hotels:</strong> {hotel_quantity:,}</p>
        <p><strong>Countries:</strong> {len(selected_countries)}</p>
        <p><strong>File Status:</strong> {'✅ Uploaded' if uploaded_file else '⏳ Pending'}</p>
    </div>
    """, unsafe_allow_html=True)
    
    # Selected countries display
    if selected_countries:
        st.markdown("#### 🌍 Selected Countries")
        for country in selected_countries[:10]:  # Show first 10
            st.markdown(f"• {country}")
        if len(selected_countries) > 10:
            st.markdown(f"... and {len(selected_countries) - 10} more")
    
    # Webhook test section
    st.markdown("#### 🔧 Webhook Test")
    if st.button("🧪 Test Webhook Connection", use_container_width=True):
        with st.spinner('Testing webhook connection...'):
            try:
                test_response = requests.get("http://localhost:5678/webhook-test/ClientDataQuestion", timeout=5)
                if test_response.status_code in [200, 404, 405]:  # These are expected responses
                    st.success("✅ Webhook endpoint is reachable!")
                else:
                    st.warning(f"⚠️ Webhook responded with status: {test_response.status_code}")
            except requests.exceptions.ConnectionError:
                st.error("❌ Cannot connect to webhook. Ensure n8n is running on localhost:5678")
            except Exception as e:
                st.error(f"❌ Connection test failed: {str(e)}")

# Submit button
st.markdown("---")
col_submit1, col_submit2, col_submit3 = st.columns([1, 2, 1])

with col_submit2:
    if st.button("🚀 Submit Questionnaire", use_container_width=True):
        if selected_countries and (uploaded_file is not None):
            # Get hotel IDs list
            try:
                df = pd.read_csv(uploaded_file)
                hotel_ids_list = df.iloc[:, 0].tolist()
                top_1000_hotels = hotel_ids_list[:1000] if len(hotel_ids_list) > 1000 else hotel_ids_list
            except:
                top_1000_hotels = []
            
            st.session_state.form_submitted = True
            
            # Show processing message
            with st.spinner('Sending data to webhook...'):
                # Send to webhook
                success, message = send_to_webhook(hotel_quantity, selected_countries, top_1000_hotels)
            
            if success:
                st.balloons()
                st.success(f"✅ {message}")
                
                # Create results summary
                st.markdown("""
                <div class="result-card">
                    <h3>✅ Questionnaire Submitted Successfully!</h3>
                    <p>Your hotel data collection parameters have been recorded and sent to the processing system.</p>
                </div>
                """, unsafe_allow_html=True)
                
                # Show webhook details
                st.info("""
                📤 **Data sent to webhook:**
                - **Config Summary CSV**: Hotel quantity, countries count, submission date
                - **Selected Countries CSV**: List of all selected destination countries  
                - **Hotel IDs CSV**: Uploaded hotel IDs (up to 1000)
                - **Webhook URL**: http://localhost:5678/webhook-test/ClientDataQuestion
                """)
                
            else:
                st.error(f"❌ Failed to send to webhook: {message}")
                st.warning("⚠️ Data was collected but could not be sent to the processing system.")
            
            # Show final summary regardless of webhook status
            summary_data = {
                "Parameter": ["Hotel Quantity", "Selected Countries", "Uploaded Hotel IDs", "Webhook Status"],
                "Value": [
                    f"{hotel_quantity:,}",
                    f"{len(selected_countries)} countries",
                    f"{len(top_1000_hotels) if uploaded_file else 0} hotels",
                    "✅ Sent" if success else "❌ Failed"
                ]
            }
            
            st.markdown("#### 📊 Final Summary")
            st.dataframe(pd.DataFrame(summary_data), use_container_width=True)
            
            # Show CSV previews in expandable sections
            if success:
                col_prev1, col_prev2, col_prev3 = st.columns(3)
                
                with col_prev1:
                    with st.expander("📋 Config Summary CSV"):
                        config_preview = pd.DataFrame({
                            'Parameter': ['Hotel Quantity', 'Number of Countries', 'Submission Date'],
                            'Value': [hotel_quantity, len(selected_countries), datetime.now().strftime("%Y-%m-%d %H:%M:%S")]
                        })
                        st.dataframe(config_preview)
                
                with col_prev2:
                    with st.expander("🌍 Countries CSV"):
                        countries_preview = pd.DataFrame({
                            'Country_Name': selected_countries[:5],
                            'Selection_Order': range(1, min(6, len(selected_countries) + 1))
                        })
                        st.dataframe(countries_preview)
                        if len(selected_countries) > 5:
                            st.text(f"... and {len(selected_countries) - 5} more countries")
                
                with col_prev3:
                    with st.expander("🏨 Hotel IDs CSV"):
                        if top_1000_hotels:
                            hotels_preview = pd.DataFrame({
                                'Hotel_ID': top_1000_hotels[:5],
                                'Order': range(1, min(6, len(top_1000_hotels) + 1))
                            })
                            st.dataframe(hotels_preview)
                            if len(top_1000_hotels) > 5:
                                st.text(f"... and {len(top_1000_hotels) - 5} more hotel IDs")
                        else:
                            st.text("No hotel IDs provided")
            
        else:
            st.error("❌ Please complete all required fields: select countries and upload a CSV file")

# Footer
st.markdown("---")
st.markdown(
    """
    <div style="text-align: center; color: #666; padding: 20px;">
        🏨 Client Data Collection System | Built with Streamlit
    </div>
    """, 
    unsafe_allow_html=True
)