import "../css/app.css"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")


//---------------------------- Local Stream -----------------------------//
async function initStream() {
    try{
        // Gets local media from browser and stores it in steam.
        const stream = await navigator.mediaDevices.getUserMedia({
            audio: true,
            video: true,
            width: "1280" });
        
        // Stores stream in global constant.
        localSteam = stream
        
        // Sets local-video element to stream from webcam.
        document.getElementById("local-video").srcObject = stream;

    } catch (e) {
        console.log(e)
    }
}

let Hooks = {}
Hooks.JoinCall = {
    mounted() {
        initStream();
    }
}

//---------------------------- Remote Stream -----------------------------//

var users = {};

function addUserConnection(userUuid) {
    if (users[userUuid] === undefined){
        users[userUuid] = {
            peerConnection: null
        }
    }
    return users
}

function removeUserConnection(userUuid){
    delete users[userUuid]
    return users
}

Hooks.InitUser = {
    mounted() {
        addUserConnection(this.el.dataset.userUuid)
    },

    destroyed() {
        removeUserConnection();
    }
}


//---------------------------- Web RTC -----------------------------//

// live view    - LiveView hooks 'this' object.
// from User    - The user to create the peer connection with.
// offer        - Stores an SDP offer if passed to function.
function createPeerConnection(liveView, fromUser, offer) {
    
    let newPeerConnection = RTCPeerConnection({
        iceServers: [
            {urls: "stun.12connect.com:3478"}
        ]
    });

    // Add this new peer connection to `users` object.
    users[fromUser].peerConnection = newPeerConnection;
    // Add each local track to the RTCPeerConnection.
    localSteam.getTracks().forEach(track => newPeerConnection.addTrack(track, localStream));

    // If creating an answer, rather than an initial offer
    if(offer != undefined) {
        newPeerConnection.setRemoteDescription({type: "offer", sdp: offer });
        newPeerConnection.createAnswer()
            .then((answer) => {
                newPeerConnection.setLocalDescription(answer)
                console.log("Sending answer to requester.")
                liveView.pushEvent("new answer", {toUser: fromUser, description: answer})
            })
            .catch((err) => console.log(err));
    }

    newPeerConnection.onicecanidate = async ({canidate}) => {
        liveView.pushEvent("new_ice_canidate", {toUser: fromUser, canidate})
    }

    if (offer === undefined) {
        newPeerConnection.onnegotiationneeded = async () => {
          try {
            newPeerConnection.createOffer()
              .then((offer) => {
                newPeerConnection.setLocalDescription(offer)
                console.log("Sending this OFFER to the requester:", offer)
                liveView.pushEvent("new_sdp_offer", {toUser: fromUser, description: offer})
              })
              .catch((err) => console.log(err))
          }
          catch (error) {
            console.log(error)
          }
        }
      }
    
      // When the data is ready to flow, add it to the correct video.
      newPeerConnection.ontrack = async (event) => {
        console.log("Track received:", event)
        document.getElementById(`video-remote-${fromUser}`).srcObject = event.streams[0]
      }
    
      return newPeerConnection;
}


Hooks.HandleOfferRequest = {
    mounted () {
        console.log("new offer request from: ", this.el.dataset.fromUserUuid)
        let fromUser = this.el.dataset.fromUserUuid
        createPeerConnection(this, fromUser)
    }
}

Hooks.HandleIceCandidateOffer = {
    mounted () {
        let data = this.el.dataset
        let fromUser = data.fromUserUuid
        let iceCandidate = JSON.parse(data.iceCandidate)
        let peerConnection = users[fromUser].peerConnection

        console.log("new ice candidate from: ", fromUser, iceCandidate)

        peerConnection.addIceCandidate(iceCandidate)
    }
}

Hooks.HandleSdpOffer = {
    mounted () {
        let data = this.el.dataset
        let fromUser = data.fromUserUuid
        let sdp = data.sdp

        if (sdp != "") {
            console.log("new sdp OFFER from: ", data.fromUserUuid, data.sdp)

            createPeerConnection(this, fromUser, sdp)
        }
    }
}

Hooks.HandleAnswer = {
    mounted () {
        let data = this.el.dataset
        let fromUser = data.fromUserUuid
        let sdp = data.sdp
        let peerConnection = users[fromUserUuid].peerConnection

        if (sdp != "") {
            console.log("new sdp ANSWER from: ", fromUser, sdp)
            peerConnection.setRemoteDescription({type: "answer", sdp: sdp})
        }
    }

}


let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})
// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"});
// window.addEventListener("phx:page-loading-start", info => NProgress.start());
window.addEventListener("phx:page-loading-start", info => topbar.show());
window.addEventListener("phx:page-loading-stop", info => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
