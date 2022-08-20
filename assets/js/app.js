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
        addUserConnection(this.el.dataset.userUuidq)
    },

    destroyed() {
        removeUserConnection();
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
