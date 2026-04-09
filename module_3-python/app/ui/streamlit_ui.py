import time
import streamlit as st

from app.services.chat_service import answer_user
from app.models.book_schemas import ChatResultResponseType

def run() -> None:
    st.set_page_config(page_title="BookChat", layout="wide")
    
    st.title("BookChat")
    st.caption("Ask me anything!")

    # Initialize chat history
    if "messages" not in st.session_state:
        st.session_state.messages = [{"role": "assistant", "content": "Let's start chatting! What book are you interested in?"}]

    # Display chat messages from history on app rerun
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])

    # Accept user input
    if prompt := st.chat_input("Your query"):
        # Add user message to chat history
        st.session_state.messages.append({"role": "user", "content": prompt})
        # Display user message in chat message container
        with st.chat_message("user"):
            st.markdown(prompt)

        # Display assistant response in chat message container
        with st.chat_message("assistant"):
            message_placeholder = st.empty()
            full_response = ""
            query_result = answer_user(prompt)

            if query_result is None:
                st.error("Internal error: no response from recommendation service.")
                return

            if query_result.response_type in (ChatResultResponseType.SUCCESSFUL, ChatResultResponseType.WEB_SEARCH):
                assistant_response = [
                    f"**Recommendation:** {query_result.recommendation.recommended_title}\n\n",
                    f"**Reason:** {query_result.recommendation.reason}\n\n",
                    f"**Themes:** {', '.join(query_result.recommendation.themes)}\n\n",
                    f"**Detailed Summary:** {query_result.detailed_summary}\n\n"
                ]
                # Simulate stream of response with milliseconds delay
                for chunk in assistant_response:
                    full_response += chunk
                    time.sleep(0.05)
                    # Add a blinking cursor to simulate typing
                    message_placeholder.markdown(full_response + "▌")
                message_placeholder.markdown(full_response)

            elif query_result.response_type == ChatResultResponseType.PROFANITY_DETECTED:
                full_response = query_result.recommendation.reason
                message_placeholder.markdown(full_response)
            
            elif query_result.response_type == ChatResultResponseType.NO_RECOMMENDATION:
                full_response = query_result.recommendation.reason
                full_response += "\n\n**Follow-up question:** " + query_result.recommendation.follow_up_question

                message_placeholder.markdown(full_response)
            
        # Add assistant response to chat history
        st.session_state.messages.append({"role": "assistant", "content": full_response})