struct SliderCaptcha: Captcha {
    let key: String
    let board: String
    let threadNumber: Int?
    let baseURL = URL(string: "https://sys.4chan.org/")

    func makeHTML(theme: Theme, tintColor: UIColor) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1">
            <title>Captcha</title>

            <style>
                html, body {
                    margin: 0;
                    background-color: \(theme.backgroundColor.toHexString());
                    color: \(theme.textColor.toHexString());
                    font-family: -apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif;
                }

                #container {
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100%;
                }

                #captcha {
                    display: none;
                }

                #captcha-img {
                    border-radius: 12px;
                }

                #captcha-slider {
                    -webkit-appearance: none;
                    width: 100%;
                    margin: 18px 0;
                    background: none;
                }

                #captcha-slider::-webkit-slider-thumb {
                    -webkit-appearance: none;
                    appearance: none;
                    width: 24px;
                    height: 24px;
                    border-radius: 24px;
                    background: \(tintColor.toHexString());
                    cursor: pointer;
                    margin-top: -8px;
                }

                input[type=range]::-webkit-slider-runnable-track {
                    height: 8px;
                    background: \(theme.separatorColor.toHexString());
                    border: none;
                    border-radius: 3px;
                }

                #captcha-input {
                    background: none;
                    outline: none;
                    border: 1px solid \(theme.separatorColor.toHexString());
                    color: \(theme.textColor.toHexString());
                    margin: 6px 0;
                    padding: 8px 0;
                    border-radius: 4px;
                    width: 100%;
                    text-align: center;
                    font-weight: bold;
                    font-size: 1em;
                    text-transform: uppercase;
                }

                #status {
                    font-size: 1em;
                    text-align: center;
                    padding: 0 24px;
                    color: \(theme.altTextColor.toHexString());
                }
            </style>
        </head>
        <body>
            <div id="container">
                <div id="captcha">
                    <img id="captcha-img" src="">
                    <div>
                        <input type="range" min="1" max="100" value="50" class="slider" id="captcha-slider">
                    </div>
                    <input
                        type="text"
                        autocapitalize="characters"
                        spellcheck="false"
                        autocomplete="off"
                        autocorrect="off"
                        id="captcha-input"
                        autofocus>
                </div>
                <div id="status">Loading captcha...</div>
            </div>

            <script>
                const captcha = document.getElementById("captcha");
                const status = document.getElementById("status");
                const captchaImg = document.getElementById("captcha-img");
                const captchaSlider = document.getElementById("captcha-slider");
                const captchaInput = document.getElementById("captcha-input");
                const cloudflare = document.getElementById("cloudflare");
                var challenge = null;

                function captchaBackground(data, xOffset) {
                    return `url('data:image/png;base64,${data}') ${xOffset}% 0%`;
                }

                function displayCaptcha(response) {
                    captcha.style.display = 'block';
                    status.style.display = 'none';
                    challenge = response["challenge"];
                    captchaImg.setAttribute("src", "data:image/png;base64, " + response["img"]);
                    const bg = response["bg"];
                    captchaSlider.value = 0;
                    captchaImg.style.background = captchaBackground(bg, 0);
                    captchaInput.focus();
                    captchaSlider.oninput = () => {
                        captchaImg.style.background = captchaBackground(bg, captchaSlider.value);
                    };
                }

                function loadCaptcha(board, thread) {
                    let url = 'https://sys.4chan.org/captcha?board=' + board;
                    if (thread) {
                        url += "&thread_id=" + thread;
                    }

                    fetch(url, {
                        method: 'GET',
                        redirect: 'follow',
                        mode: 'cors',
                    })
                    .then((response) => {
                        if (response.status == 503) {
                            response.text().then((html) => {
                                webkit.messageHandlers.cloudflare.postMessage(html);
                            });
                        } else if (response.status == 200) {
                            response.json().then((json) => {
                                if (json["error"]) {
                                    status.style.display = 'block';
                                    if (json["cd"]) {
                                        let cooldown = json["cd"];
                                        let updateCooldown = () => {
                                            status.innerHTML = "Too many requests. <br>Retrying in " + cooldown + "s";
                                            cooldown = Math.max(0, cooldown - 1);
                                        };
                                        setTimeout(() => loadCaptcha(board, thread), cooldown * 1000);
                                        updateCooldown();
                                        setInterval(updateCooldown, 1000);
                                    } else {
                                        status.innerHTML = json["error"];
                                    }
                                } else {
                                    displayCaptcha(json);
                                }
                            })
                        }
                    })
                }

                function updateOffset() {
                    captchaImg.style.background = captchaBackground(response["bg"], slider.value);
                }

                function submitCaptcha() {
                    webkit.messageHandlers.submit.postMessage({input: captchaInput.value, challenge: challenge});
                }

                window.visualViewport.onresize = () => {
                    document.body.style.height = window.visualViewport.height + 'px';
                    captchaImg.scrollIntoView({block: 'center'});
                };

                captchaInput.onkeypress = (event) => {
                    if (event.keyCode == 13) {
                        submitCaptcha();
                    }
                };

                captchaSlider.oninput = updateOffset;
                loadCaptcha('\(board)', \(threadNumber.flatMap(String.init) ?? "null"));
            </script>
        </body>
        </html>
        """
    }
}
